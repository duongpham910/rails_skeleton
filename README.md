# RAILS SKELETON

## Build environment

### Development (Docker)

1. Clone and enter project's folder

   ```console
   git clone # using SSH or HTTPS method
   cd rails_skeleton
   ```

2. Config database and credentials

   ```console
   cp config/database.yml.example config/database.yml
   cp config/master.key.example config/master.key
   ```

3. Create MYSQL config file

   ```console
   touch docker/my.cnf
   ```

4. Build and run docker

   a. Builds, (re)creates, starts, and attaches to containers for a service

   ```console
   chmod +x ./docker/scripts/docker-entrypoint.sh
   docker-compose up -d && docker attach $(docker-compose ps -q web)
   ```

   b. Open docker container bash

   Open new tab in terminal

   ```console
   docker-compose exec web bash
   ```

   c. Generate dummy data.

   ```console
   rails db:create db:migrate
   ```
5. When docker is running, open <http://localhost:3001>

### Staging

- TO BE CONTINUED

### Production

#### Setup Puma service

```console
rails setup:puma_service
```

## Code Quality Assurance

Run each of these commands then fix any problem that appears

```console
rubocop
rails_best_practices .
brakeman
```
