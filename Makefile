build:
	docker-compose build

down:
	docker-compose down --volumes

run:
	make down && docker-compose up

run-scaled:
	make down && docker-compose up --scale spark-worker=3

stop:
	docker-compose stop

submit:
	docker exec da-spark-master spark-submit --master yarn --deploy-mode cluster ./apps/$(app)