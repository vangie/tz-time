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
	bin/waitForServer.sh http://localhost:8000/2016-08-15/proxy/tz-time/tz-time/
	npm run integration:test
	kill -2 `cat $<` && rm $<

package:
	fun build
	fun package --oss-bucket tz-staging

stack_name := tz-e2e-$(shell date +%s)

e2e-test: 
	# deploy e2e 
	bin/deployE2EStack.sh $(stack_name)
	# run test
	npm run e2e:test
	# cleanup
	bin/delRosStack.sh $(stack_name)

deploy:
	fun deploy --use-ros --stack-name tz-staging --assume-yes