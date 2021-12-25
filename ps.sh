echo $(kubectl get secret es-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
