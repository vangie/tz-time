clean:
	rm -rf node_modules/

install:
	fun install sbox -f tz-time --cmd 'npm install'

ut:
	fun install sbox -f tz-time --cmd 'npm test'

package: clean
	fun install
	fun package --oss-bucket tz-staging

deploy:
	fun deploy --use-ros --stack-name tz-staging --assume-yes