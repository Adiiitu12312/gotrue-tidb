package utilities

import (
	"errors"
	"strconv"
	"strings"

	"github.com/go-sql-driver/mysql"
	"github.com/jackc/pgconn"
	"github.com/jackc/pgerrcode"
)

// PostgresError is a custom error struct for marshalling Postgres errors to JSON.
type PostgresError struct {
	Code           string `json:"code"`
	HttpStatusCode int    `json:"-"`
	Message        string `json:"message"`
	Hint           string `json:"hint,omitempty"`
	Detail         string `json:"detail,omitempty"`
}

// NewPostgresError returns a new PostgresError if the error was from a publicly
// accessible Postgres or MySQL/TiDB error.
func NewPostgresError(err error) *PostgresError {
	if err == nil {
		return nil
	}

	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && isPubliclyAccessiblePostgresError(pgErr.Code) {
		return &PostgresError{
			Code:           pgErr.Code,
			HttpStatusCode: getHttpStatusCodeFromPostgresErrorCode(pgErr.Code),
			Message:        pgErr.Message,
			Detail:         pgErr.Detail,
			Hint:           pgErr.Hint,
		}
	}

	var myErr *mysql.MySQLError
	if errors.As(err, &myErr) {
		code := ""
		switch myErr.Number {
		case 1062: // Duplicate entry
			code = pgerrcode.UniqueViolation // 23505
		case 1451, 1452: // Foreign key violation
			code = pgerrcode.ForeignKeyViolation // 23503
		case 1048: // Not null violation
			code = pgerrcode.NotNullViolation // 23502
		default:
			code = pgerrcode.IntegrityConstraintViolation // 23000
		}
		return &PostgresError{
			Code:           code,
			HttpStatusCode: getHttpStatusCodeFromPostgresErrorCode(code),
			Message:        myErr.Message,
		}
	}

	errStr := err.Error()
	if strings.Contains(errStr, "Duplicate entry") || strings.Contains(errStr, "Error 1062") {
		return &PostgresError{
			Code:           pgerrcode.UniqueViolation,
			HttpStatusCode: 500,
			Message:        errStr,
		}
	}

	return nil
}
func (pg *PostgresError) IsUniqueConstraintViolated() bool {
	// See https://www.postgresql.org/docs/current/errcodes-appendix.html for list of error codes
	return pg.Code == "23505"
}

// isPubliclyAccessiblePostgresError checks if the Postgres error should be
// made accessible.
func isPubliclyAccessiblePostgresError(code string) bool {
	if len(code) != 5 {
		return false
	}

	// default response
	return getHttpStatusCodeFromPostgresErrorCode(code) != 0
}

// getHttpStatusCodeFromPostgresErrorCode maps a Postgres error code to a HTTP
// status code. Returns 0 if the code doesn't map to a given postgres error code.
func getHttpStatusCodeFromPostgresErrorCode(code string) int {
	if code == pgerrcode.RaiseException ||
		code == pgerrcode.IntegrityConstraintViolation ||
		code == pgerrcode.RestrictViolation ||
		code == pgerrcode.NotNullViolation ||
		code == pgerrcode.ForeignKeyViolation ||
		code == pgerrcode.UniqueViolation ||
		code == pgerrcode.CheckViolation ||
		code == pgerrcode.ExclusionViolation {
		return 500
	}

	// Use custom HTTP status code if Postgres error was triggered with `PTXXX`
	// code. This is consistent with PostgREST's behaviour as well.
	if strings.HasPrefix(code, "PT") {
		if httpStatusCode, err := strconv.ParseInt(code[2:], 10, 0); err == nil {
			return int(httpStatusCode)
		}
	}

	return 0
}
