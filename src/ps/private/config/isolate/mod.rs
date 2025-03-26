use crate::ps::private::utils;
use serde::Deserialize;
use std::option::Option;

#[derive(Debug, Deserialize, Clone, Default)]
pub struct IsolateConfigDto {
    pub exclude_submodules: Option<bool>,
    pub include_untracked: Option<bool>,
}

impl utils::Mergable for IsolateConfigDto {
    /// Merge the provided b with self overriding with any present values
    fn merge(&self, b: &Self) -> Self {
        IsolateConfigDto {
            exclude_submodules: b.exclude_submodules.or(self.exclude_submodules),
            include_untracked: b.include_untracked.or(self.include_untracked),
        }
    }
}
