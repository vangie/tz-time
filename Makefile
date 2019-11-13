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

e2e-test: install
	npm run e2e:test

package: clean
	#fun install
	npm install --production
	fun package --oss-bucket tz-staging

deploy:
	fun deploy --use-ros --stack-name tz-staging --assume-yes | tee deploy.log
	cat deploy.log | grep '^url:' | sed -e "s/^url: //" | sed -e 's/^/DEPLOYED_URL=/' > .env
	cat .env
	rm deploy.log