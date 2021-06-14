kubectl get pods -o go-template --template  '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l component=isolated-follower | xargs -n1 kubectl logs -c freon --tail=11
