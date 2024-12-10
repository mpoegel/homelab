#!/bin/bash

certbot certonly --cert-name oldno.name --standalone \
    -d pizza.oldno.name,oldno.name,recipes.oldno.name,login.oldno.name,games.oldno.name,photos.oldno.name,matt.oldno.name,matt.poegel.dev
