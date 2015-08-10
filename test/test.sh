# if ! bundle exec vagrant box list | grep simple_cloud 1>/dev/null; then
#     bundle exec vagrant box add simple_cloud box/simple_cloud.box
# fi

cd test

bundle exec vagrant up --provider=simple_cloud
bundle exec vagrant up
bundle exec vagrant provision
bundle exec vagrant rebuild
bundle exec vagrant halt
bundle exec vagrant destroy

cd ..
