# if ! bundle exec vagrant box list | grep simple_cloud 1>/dev/null; then
#     bundle exec vagrant box add simple_cloud box/simple_cloud.box
# fi

cd test

bundle _1.7.9_ exec vagrant up --provider=simple_cloud
bundle _1.7.9_ exec vagrant up
bundle _1.7.9_ exec vagrant provision
bundle _1.7.9_ exec vagrant rebuild
bundle _1.7.9_ exec vagrant halt
bundle _1.7.9_ exec vagrant destroy

cd ..
