# Домашняя работа к занятию "3.5. Файловые системы" 

#### 1. Узнайте о sparse (разряженных) файлах.  
    
	Разрежённый файл (англ. sparse file) — файл, в котором последовательности нулевых байтов заменены на информацию об этих последовательностях (список дыр).  
	
#### 2. Могут ли файлы, являющиеся жесткой ссылкой на один объект, иметь разные права доступа и владельца? Почему?  
    
	Не могут, так как ссылки будут на один и тот же inode, где хранятся права доступа и прочие атрибуты файла.   
	       
#### 3. Сделайте vagrant destroy на имеющийся инстанс Ubuntu. Замените содержимое Vagrantfile следующим:  
       Vagrant.configure("2") do |config|  
         config.vm.box = "bento/ubuntu-20.04"  
         config.vm.provider :virtualbox do |vb|  
           lvm_experiments_disk0_path = "/tmp/lvm_experiments_disk0.vmdk"  
           lvm_experiments_disk1_path = "/tmp/lvm_experiments_disk1.vmdk"  
           vb.customize ['createmedium', '--filename', lvm_experiments_disk0_path, '--size', 2560]  
           vb.customize ['createmedium', '--filename', lvm_experiments_disk1_path, '--size', 2560]  
           vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', lvm_experiments_disk0_path]  
           vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', lvm_experiments_disk1_path]  
         end  
       end  
       Данная конфигурация создаст новую виртуальную машину с двумя дополнительными неразмеченными дисками по 2.5 Гб.  
	   
>	Выполнили vagrant destroy и создали новую виртуальную машину с двумя дополнительными неразмеченными дисками по 2.5 Гб.  
	
```bash 
	vagrant@vagrant:~$ lsblk
	NAME                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
	sda                    8:0    0   64G  0 disk
	├─sda1                 8:1    0  512M  0 part /boot/efi
	├─sda2                 8:2    0    1K  0 part
	└─sda5                 8:5    0 63.5G  0 part
	  ├─vgvagrant-root   253:0    0 62.6G  0 lvm  /
	  └─vgvagrant-swap_1 253:1    0  980M  0 lvm  [SWAP]
	sdb                    8:16   0  2.5G  0 disk
	sdc                    8:32   0  2.5G  0 disk
```
			
#### 4. Используя fdisk, разбейте первый диск на 2 раздела: 2 Гб, оставшееся пространство.
	
```bash
	vagrant@vagrant:~$ sudo fdisk /dev/sdb  
	
	Welcome to fdisk (util-linux 2.34).  
	Changes will remain in memory only, until you decide to write them.  
	Be careful before using the write command.  
	
	Device does not contain a recognized partition table.  
	Created a new DOS disklabel with disk identifier 0x409d782d.  
	
	Command (m for help): n  
	Partition type  
	   p   primary (0 primary, 0 extended, 4 free)  
	   e   extended (container for logical partitions)  
	Select (default p): p  
	Partition number (1-4, default 1): 1  
	First sector (2048-5242879, default 2048): 2048  
	Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-5242879, default 5242879): +2G  
	
	Created a new partition 1 of type 'Linux' and of size 2 GiB.  
	
	Command (m for help): n  
	Partition type  
	   p   primary (1 primary, 0 extended, 3 free)  
	   e   extended (container for logical partitions)  
	Select (default p): p  
	Partition number (2-4, default 2): 2  
	First sector (4196352-5242879, default 4196352): 4196352  
	Last sector, +/-sectors or +/-size{K,M,G,T,P} (4196352-5242879, default 5242879): 5242879  
	
	Created a new partition 2 of type 'Linux' and of size 511 MiB.  
	
	Command (m for help): w  
	The partition table has been altered.  
	Calling ioctl() to re-read partition table.  
	Syncing disks.  
	
	vagrant@vagrant:~$ lsblk  
	NAME                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT  
	sda                    8:0    0   64G  0 disk  
	├─sda1                 8:1    0  512M  0 part /boot/efi  
	├─sda2                 8:2    0    1K  0 part  
	└─sda5                 8:5    0 63.5G  0 part  
	  ├─vgvagrant-root   253:0    0 62.6G  0 lvm  /  
          └─vgvagrant-swap_1 253:1    0  980M  0 lvm  [SWAP]  
	sdb                    8:16   0  2.5G  0 disk  
	├─sdb1                 8:17   0    2G  0 part  
	└─sdb2                 8:18   0  511M  0 part  
		sdc                    8:32   0  2.5G  0 disk  
```

#### 5. Используя sfdisk, перенесите данную таблицу разделов на второй диск.  
	
```bash
	vagrant@vagrant:~$ sudo sfdisk --dump /dev/sdb | sudo sfdisk /dev/sdc  
	Checking that no-one is using this disk right now ... OK  

	Disk /dev/sdc: 2.51 GiB, 2684354560 bytes, 5242880 sectors  
	Disk model: VBOX HARDDISK    
	Units: sectors of 1 * 512 = 512 bytes  
	Sector size (logical/physical): 512 bytes / 512 bytes  
	I/O size (minimum/optimal): 512 bytes / 512 bytes  

	>>> Script header accepted.  
	>>> Script header accepted.  
	>>> Script header accepted.  
	>>> Script header accepted.  
	>>> Created a new DOS disklabel with disk identifier 0xf23b12c8.  
	/dev/sdc1: Created a new partition 1 of type 'Linux' and of size 2 GiB.  
	/dev/sdc2: Created a new partition 2 of type 'Linux' and of size 511 MiB.  
	/dev/sdc3: Done.  

	New situation:  
	Disklabel type: dos  
	Disk identifier: 0xf23b12c8  

	Device     Boot   Start     End Sectors  Size Id Type  
	/dev/sdc1          2048 4196351 4194304    2G 83 Linux  
	/dev/sdc2       4196352 5242879 1046528  511M 83 Linux  

	The partition table has been altered.  
	Calling ioctl() to re-read partition table.  
	Syncing disks.  
```  

	
#### 6. Соберите mdadm RAID1 на паре разделов 2 Гб.  
	
```bash
vagrant@vagrant:~$ sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd{b1,c1}  
```

#### 7. Соберите mdadm RAID0 на второй паре маленьких разделов.  
	
```bash
	vagrant@vagrant:~$ sudo mdadm --create /dev/md1 --level=0 --raid-devices=2 /dev/sd{b2,c2}  	
```

#### 8. Создайте 2 независимых PV на получившихся md-устройствах.  

```bash
	vagrant@vagrant:~$ sudo pvcreate /dev/md0  
	vagrant@vagrant:~$ sudo pvcreate /dev/md1  
```

#### 9. Создайте общую volume-group на этих двух PV.  
	
```bash
	vagrant@vagrant:~$ sudo pvcreate /dev/md1  
```

#### 10. Создайте LV размером 100 Мб, указав его расположение на PV с RAID0.  
	
```bash
	vagrant@vagrant:~$ sudo lvcreate -L 100M vg1 /dev/md1  
	Logical volume "lvol0" created.  
		
#### 11. Создайте mkfs.ext4 ФС на получившемся LV.  
	
```bash
	vagrant@vagrant:~$ sudo mkfs.ext4 /dev/vg1/lvol0	
```
	
#### 12. Смонтируйте этот раздел в любую директорию, например, /tmp/new.  

```bash
	vagrant@vagrant:~$ mkdir /tmp/new  
	vagrant@vagrant:~$ mount /dev/vg1/lvol0 /tmp/new	 
```	
	
#### 13. Поместите туда тестовый файл, например wget https://mirror.yandex.ru/ubuntu/ls-lR.gz -O /tmp/new/test.gz.  

```bash
	vagrant@vagrant:~$ sudo wget https://mirror.yandex.ru/ubuntu/ls-lR.gz -O /tmp/new/test.gz
```	
	
#### 14. Прикрепите вывод lsblk.  
	
```bash
vagrant@vagrant:~$ lsblk  
NAME                 MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT  
sda                    8:0    0   64G  0 disk    
├─sda1                 8:1    0  512M  0 part  /boot/efi  
├─sda2                 8:2    0    1K  0 part  
└─sda5                 8:5    0 63.5G  0 part  
  ├─vgvagrant-root   253:0    0 62.6G  0 lvm   /  
  └─vgvagrant-swap_1 253:1    0  980M  0 lvm   [SWAP]  
sdb                    8:16   0  2.5G  0 disk  
├─sdb1                 8:17   0    2G  0 part  
│ └─md0                9:0    0    2G  0 raid1  
└─sdb2                 8:18   0  511M  0 part  
  └─md1                9:1    0 1018M  0 raid0  
    └─vg1-lvol0      253:2    0  100M  0 lvm   /tmp/new  
sdc                    8:32   0  2.5G  0 disk  
├─sdc1                 8:33   0    2G  0 part  
│ └─md0                9:0    0    2G  0 raid1  
└─sdc2                 8:34   0  511M  0 part  
  └─md1                9:1    0 1018M  0 raid0  
    └─vg1-lvol0      253:2    0  100M  0 lvm   /tmp/new 
```
	
	
#### 15. Протестируйте целостность файла:  

```bash
	vagrant@vagrant:~$ gzip -t /tmp/new/test.gz  
	vagrant@vagrant:~$ echo $?  
	0  
```	 
	 
#### 16. Используя pvmove, переместите содержимое PV с RAID0 на RAID1.  

```bash
	vagrant@vagrant:~$ sudo pvmove --name lvol0 /dev/md1 /dev/md0  
	/dev/md1: Moved: 12.00%  
	/dev/md1: Moved: 100.00%  
```	
	
#### 17. Сделайте --fail на устройство в вашем RAID1 md.

```bash
	vagrant@vagrant:~$ sudo mdadm /dev/md0 --fail /dev/sdb1  
	mdadm: set /dev/sdb1 faulty in /dev/md0  
```	
	
#### 18. Подтвердите выводом dmesg, что RAID1 работает в деградированном состоянии.  

```bash
	vagrant@vagrant:~$ dmesg | grep md0  
	[85272.176337] md/raid1:md0: not clean -- starting background reconstruction  
	[85272.176340] md/raid1:md0: active with 2 out of 2 mirrors  
	[85272.176365] md0: detected capacity change from 0 to 2144337920  
	[85272.176697] md: resync of RAID array md0  
	[85285.571097] md: md0: resync done.  
	[85638.761591] md: data-check of RAID array md0  
	[85653.035310] md: md0: data-check done.  
	[89479.025673] md/raid1:md0: Disk failure on sdb1, disabling device.  
				   md/raid1:md0: Operation continuing on 1 devices.  
```
	
#### 19. Протестируйте целостность файла, несмотря на "сбойный" диск он должен продолжать быть доступен:  

```bash
	vagrant@vagrant:~$ gzip -t /tmp/new/test.gz  
	vagrant@vagrant:~$ echo $?  
	0  
```	
	
#### 20. Погасите тестовый хост, vagrant destroy.  

```bash
	lodyanyy@lodyanyy:~/vagrant$ vagrant destroy  
   	 default: Are you sure you want to destroy the 'default' VM? [y/N] y   
	==> default: Forcing shutdown of VM...  
	==> default: Destroying VM and associated drives...  
```
