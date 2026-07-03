# Comprobar que el servicio está sano
curl http://35.240.72.241

# Iniciar el incidente
curl http://35.240.72.241/start-incident

# Comprobar que ahora devuelve HTTP 500
curl -i http://35.240.72.241

# Finalizar el incidente
curl http://35.240.72.241/end-incident

# Verificar que el servicio vuelve a estar sano
curl http://35.240.72.241