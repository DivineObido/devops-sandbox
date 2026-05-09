.PHONY: up down create destroy logs health simulate clean

up:
	docker compose up -d --build
	nohup bash platform/cleanup_daemon.sh &
	bash monitor/health_poller.sh &

down:
	bash -c 'for f in envs/*.json; do [ -f "$$f" ] && bash platform/destroy_env.sh $$(basename $$f .json); done' || true
	docker compose down

create:
	@read -p "Environment name: " name; \
	read -p "TTL in seconds (default 1800): " ttl; \
	ttl=$${ttl:-1800}; \
	bash platform/create_env.sh "$$name" "$$ttl"

destroy:
	bash platform/destroy_env.sh $(ENV)

logs:
	tail -f logs/$(ENV)/app.log

health:
	@for f in envs/*.json; do \
		[ -f "$$f" ] && python3 -c "import json; d=json.load(open('$$f')); print(d['id'], d['status'], 'TTL left:', d['created_at']+d['ttl']-__import__('time').time())"; \
	done

simulate:
	bash platform/simulate_outage.sh --env $(ENV) --mode $(MODE)

clean:
	rm -rf logs/* envs/* nginx/conf.d/*.conf