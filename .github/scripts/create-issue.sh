curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer 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" \
  https://api.github.com/repos/brajagopal/test-git-workflow/issues \
  -d '{"title":"Found a bug","body":"I'\''m having a problem with this.","assignees":["octocat"],"milestone":1,"labels":["bug"]}'