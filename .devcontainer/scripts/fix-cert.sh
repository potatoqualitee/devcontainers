sudo apt-get update
sudo apt-get install -y ca-certificates curl powershell-lts git

for i in {1..50};
do
    curl -k https://localhost:8081/_explorer/emulator.pem
    if [ $? -ne 0 ];then
        sleep 2
    fi
done

sudo curl -k https://localhost:8081/_explorer/emulator.pem > ~/emulatorcert.crt
sudo cp ~/emulatorcert.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates