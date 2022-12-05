curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer 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" \
  https://api.github.com/repos/brajagopal/test-git-workflow/issues \
  -d '{"title":"Found a bug","body":"I'\''m having a problem with this.","assignees":["octocat"],"milestone":1,"labels":["bug"]}'