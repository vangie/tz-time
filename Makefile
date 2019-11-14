clean:
	rm -rf node_modules/

install:
	#fun install sbox -f tz-time --cmd 'npm install'
	npm install

unit-test:
	#fun install sbox -f tz-time --cmd 'npm test'
	npm test

funlocal.PID:
	fun local start & echo $$! > $@

integration-test: funlocal.PID 
	npm run integration:test
	kill -2 `cat $<` && rm $<


# stack_name := tz-e2e-$(shell date +%s)
stack_name := tz-e2e-1573736536

e2e-test: install
	# deploy e2e 
	fun deploy --use-ros --stack-name $(stack_name) --assume-yes | tee $(stack_name)-deploy.log
	cat $(stack_name)-deploy.log | grep '^url:' | sed -e "s/^url: //" | sed -e 's/^/DEPLOYED_URL=/' > .env
	cat .env
	rm $(stack_name)-deploy.log
	# run test
	npm run e2e:test
	# cleanup
	./delRosStack.sh $(stack_name)

package: clean
	#fun install
	npm install --production
	fun package --oss-bucket tz-staging

deploy:
	fun deploy --use-ros --stack-name tz-staging --assume-yes | tee deploy.log