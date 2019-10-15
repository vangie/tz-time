clean:
	rm -rf node_modules/

ut:
	npm install
	fun install sbox -f tz-time --cmd 'npm test'

package: clean
	fun install
	fun package --oss-bucket tz-time

deploy:
	fun deploy --use-ros --stack-name tz-staging --assume-yes