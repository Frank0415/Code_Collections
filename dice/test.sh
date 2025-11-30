sudo rmmod dice_module
sudo insmod ./dice_module.ko common_sides=50
ls -l /dev | grep dice

echo 3 | sudo tee /dev/dice0
sudo cat /dev/dice0
echo 3 | sudo tee /dev/dice1
sudo cat /dev/dice1
echo 3 | sudo tee /dev/dice2
sudo cat /dev/dice2