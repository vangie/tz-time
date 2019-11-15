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
	sleep 1

integration-test: funlocal.PID 
	npm run integration:test
	kill -2 `cat $<` && rm $<


stack_name := tz-e2e-$(shell date +%s)

e2e-test: install
	# deploy e2e 
	bin/deployE2EStack.sh $(stack_name)
	# run test
	npm run e2e:test
	# cleanup
	bin/delRosStack.sh $(stack_name)

package: clean
	#fun install
	npm install --production
	fun package --oss-bucket tz-staging

deploy:
	fun deploy --use-ros --stack-name tz-staging --assume-yes