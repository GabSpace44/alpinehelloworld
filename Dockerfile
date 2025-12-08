# Grab the latest alpine image
FROM alpine:latest

# Install python and pip, and bash (pour le debug)
RUN apk add --no-cache --update python3 py3-pip bash

# Ajouter le fichier de dépendances
ADD ./webapp/requirements.txt /tmp/requirements.txt

# --- CORRECTION POUR PIP INSTALL SUR ALPINE ---

# Installer les dépendances de compilation nécessaires
# pour que pip puisse construire certains packages (ex: psycopg2, lxml).
# .build-deps est un paquet virtuel pour faciliter le nettoyage.
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    python3-dev

# Install dependencies (cette étape ne devrait plus échouer)
RUN pip3 install --no-cache-dir -q -r /tmp/requirements.txt

# Nettoyage : Supprimer les dépendances de compilation pour réduire la taille de l'image
RUN apk del .build-deps

# --- FIN DE LA CORRECTION ---

# Add our code
ADD ./webapp/ /opt/webapp/
WORKDIR /opt/webapp

# Expose is NOT supported by Heroku, mais c'est une bonne pratique Docker
EXPOSE 5000

# Run the image as a non-root user (bonne pratique de sécurité)
RUN adduser -D myuser
USER myuser

# Run the app. CMD is required to run on Heroku
# $PORT est une variable d'environnement définie par Heroku
CMD gunicorn --bind 0.0.0.0:$PORT wsgi
