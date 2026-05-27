use super::config::{config_get_bool, ConfigGetError};

pub fn rebase_sign_arg(config: &git2::Config) -> Result<Option<&'static str>, ConfigGetError> {
    match config_get_bool(config, "commit.gpgsign")? {
        Some(true) => Ok(Some("-S")),
        _ => Ok(None),
    }
}

#[cfg(test)]
mod tests {
    use super::rebase_sign_arg;

    fn writable_config() -> (tempfile::TempDir, git2::Config) {
        let dir = tempfile::tempdir().unwrap();
        let config_path = dir.path().join("config");
        let config = git2::Config::open(&config_path).unwrap();
        (dir, config)
    }

    #[test]
    fn returns_sign_arg_when_commit_signing_enabled() {
        let (_dir, mut config) = writable_config();
        config.set_bool("commit.gpgsign", true).unwrap();

        assert_eq!(rebase_sign_arg(&config).unwrap(), Some("-S"));
    }

    #[test]
    fn returns_no_arg_when_commit_signing_disabled() {
        let (_dir, mut config) = writable_config();
        config.set_bool("commit.gpgsign", false).unwrap();

        assert_eq!(rebase_sign_arg(&config).unwrap(), None);
    }

    #[test]
    fn returns_no_arg_when_commit_signing_unset() {
        let config = git2::Config::new().unwrap();

        assert_eq!(rebase_sign_arg(&config).unwrap(), None);
    }
}
