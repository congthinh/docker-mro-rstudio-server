## Add 10 users for Data Team
for u in {0..10}
do 
  useradd user$u && echo "user$u:user$u" | chpasswd
  mkdir /home/user$u && chown user$u:user$u /home/user$u
  addgroup user$u staff
done


