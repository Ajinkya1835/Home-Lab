.RECIPEPREFIX = >
# Order matters: homepage joins the networks the others create, so it starts last.
STACKS := immich jellyfin netdata scrutiny dozzle filebrowser vaultwarden n8n edge homepage

.PHONY: validate up down ps pull

validate:
> ./scripts/validate.sh

up:
> @for s in $(STACKS); do \
>   [ -f docker/$$s/.env ] || { [ -f docker/$$s/.env.example ] && cp docker/$$s/.env.example docker/$$s/.env && echo "created docker/$$s/.env - edit it"; }; \
>   (cd docker/$$s && docker compose up -d) || exit 1; \
> done

down:
> @for s in $(STACKS); do (cd docker/$$s && docker compose down); done

ps:
> @docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

pull:
> @for s in $(STACKS); do (cd docker/$$s && docker compose pull); done
