package test

import (
	"os"

	"github.com/supabase/auth/internal/conf"
	"github.com/supabase/auth/internal/storage"
)

func SetupDBConnection(globalConfig *conf.GlobalConfiguration) (*storage.Connection, error) {
	if dbURL := os.Getenv("DATABASE_URL"); dbURL != "" {
		globalConfig.DB.URL = dbURL
	}
	if driver := os.Getenv("GOTRUE_DB_DRIVER"); driver != "" {
		globalConfig.DB.Driver = driver
	}
	return storage.Dial(globalConfig)
}
