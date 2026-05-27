use super::super::private::git;
use super::super::private::utils;

#[derive(Debug)]
pub enum RebaseError {
    RepositoryMissing,
    GetGitConfigFailed,
    GetCommitSigningConfigFailed(git::config::ConfigGetError),
    GetHeadBranchNameFailed,
    GetUpstreamBranchNameFailed,
    RebaseFailed(utils::ExecuteError),
}

pub fn rebase(continue_rebase: bool) -> Result<(), RebaseError> {
    if continue_rebase {
        utils::execute("git", &["rebase", "--continue"]).map_err(RebaseError::RebaseFailed)
    } else {
        let repo = git::create_cwd_repo().map_err(|_| RebaseError::RepositoryMissing)?;
        let repo_config = repo.config().map_err(|_| RebaseError::GetGitConfigFailed)?;
        let rebase_sign_arg = git::rebase_sign_arg(&repo_config)
            .map_err(RebaseError::GetCommitSigningConfigFailed)?;

        let head_ref = repo
            .head()
            .map_err(|_| RebaseError::GetHeadBranchNameFailed)?;
        let head_branch_shorthand = head_ref
            .shorthand()
            .ok_or(RebaseError::GetHeadBranchNameFailed)?;
        let head_branch_name = head_ref
            .name()
            .ok_or(RebaseError::GetHeadBranchNameFailed)?;

        let upstream_branch_name = git::branch_upstream_name(&repo, head_branch_name)
            .map_err(|_| RebaseError::GetUpstreamBranchNameFailed)?;

        let mut rebase_args = vec!["rebase", "-i"];
        if let Some(arg) = rebase_sign_arg {
            rebase_args.push(arg);
        }
        rebase_args.extend_from_slice(&[
            "--onto",
            upstream_branch_name.as_str(),
            upstream_branch_name.as_str(),
            head_branch_shorthand,
        ]);

        utils::execute("git", &rebase_args).map_err(RebaseError::RebaseFailed)
    }
}
