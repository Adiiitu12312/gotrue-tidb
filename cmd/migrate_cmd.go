package cmd

import (
	"embed"
	"fmt"
	"net/url"
	"os"
	"strings"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gobuffalo/pop/v6"
	"github.com/gobuffalo/pop/v6/logging"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var EmbeddedMigrations embed.FS

var migrateVerbose bool

var migrateCmd = cobra.Command{
	Use:  "migrate",
	Long: "Migrate database strucutures. This will create new tables and add missing columns and indexes.",
	Run:  migrate,
}

func popProgressLogger(lvl logging.Level, s string, args ...interface{}) {
	if lvl == logging.SQL || lvl == logging.Debug {
		return
	}
	if len(args) > 0 {
		s = fmt.Sprintf(s, args...)
	}
	fmt.Println(s)
}

func popNoopLogger(logging.Level, string, ...interface{}) {}

func cleanDBURL(rawURL string) string {
	if strings.Contains(rawURL, "@tcp(") {
		idx := strings.Index(rawURL, "@tcp(")
		if idx != -1 {
			afterAt := rawURL[idx+5:]
			closeParen := strings.Index(afterAt, ")")
			if closeParen != -1 {
				rawURL = rawURL[:idx+1] + afterAt[:closeParen] + afterAt[closeParen+1:]
			}
		}
	}
	return rawURL
}

func migrate(cmd *cobra.Command, args []string) {
	globalConfig := loadGlobalConfig(cmd.Context())
	globalConfig.DB.URL = cleanDBURL(globalConfig.DB.URL)
	u, err := url.Parse(globalConfig.DB.URL)
	if err != nil {
		logrus.Fatalf("%+v", errors.Wrap(err, "parsing db connection url"))
	}

	if globalConfig.DB.Driver == "" && globalConfig.DB.URL != "" {
		globalConfig.DB.Driver = u.Scheme
	}

	log := logrus.StandardLogger()

	pop.Debug = false
	if globalConfig.Logging.Level != "" {
		level, err := logrus.ParseLevel(globalConfig.Logging.Level)
		if err != nil {
			log.Fatalf("Failed to parse log level: %+v", err)
		}
		log.SetLevel(level)
	}

	switch {
	case log.Level == logrus.DebugLevel:
		pop.Debug = true
	case migrateVerbose:
		pop.SetLogger(popProgressLogger)
	case globalConfig.Logging.Level != "":
		pop.SetLogger(popNoopLogger)
	}

	dialect := globalConfig.DB.Driver
	if dialect == "tidb" {
		dialect = "mysql"
	}

	q := u.Query()
	if dialect == "postgres" {
		q.Add("application_name", "auth_migrations")
	} else if dialect == "mysql" {
		if q.Get("parseTime") == "" {
			q.Set("parseTime", "true")
		}
		if q.Get("multiStatements") == "" {
			q.Set("multiStatements", "true")
		}
	}
	u.RawQuery = q.Encode()

	deets := &pop.ConnectionDetails{
		Dialect: dialect,
		URL:     u.String(),
	}
	deets.Options = map[string]string{
		"migration_table_name": "schema_migrations",
		"Namespace":            globalConfig.DB.Namespace,
	}
	if dialect == "mysql" {
		deets.Options["parseTime"] = "true"
		deets.Options["multiStatements"] = "true"
		deets.Options["charset"] = "utf8mb4"
		deets.Options["sql_mode"] = "ANSI_QUOTES"
	}

	db, err := pop.NewConnection(deets)
	if err != nil {
		log.Fatalf("%+v", errors.Wrap(err, "opening db connection"))
	}
	defer db.Close()

	if err := db.Open(); err != nil {
		log.Fatalf("%+v", errors.Wrap(err, "checking database connection"))
	}

	if dialect == "mysql" {
		_ = db.RawQuery("SET SESSION sql_mode = CONCAT_WS(',', @@sql_mode, 'ANSI_QUOTES');").Exec()
	}

	log.Debugf("Reading migrations from executable")
	box, err := pop.NewMigrationBox(EmbeddedMigrations, db)
	if err != nil {
		log.Fatalf("%+v", errors.Wrap(err, "creating db migrator"))
	}

	mig := box.Migrator

	log.Debugf("before status")

	if log.Level == logrus.DebugLevel {
		err = mig.Status(os.Stdout)
		if err != nil {
			log.Fatalf("%+v", errors.Wrap(err, "migration status"))
		}
	}

	// turn off schema dump
	mig.SchemaPath = ""

	count, err := mig.UpTo(0)
	if err != nil {
		log.Fatalf("%v", errors.Wrap(err, "running db migrations"))
	} else {
		log.WithField("count", count).Infof("GoTrue migrations applied successfully")
	}

	log.Debugf("after status")

	if log.Level == logrus.DebugLevel {
		err = mig.Status(os.Stdout)
		if err != nil {
			log.Fatalf("%+v", errors.Wrap(err, "migration status"))
		}
	}
}
