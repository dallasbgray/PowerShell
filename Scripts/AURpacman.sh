#!bin/zsh

# TODO add option to update all, -u or --update-all
# echo "parameter 1 $1"

cd ~/Build

# check if package already exists
# if so run git pull & then rebuild
# git pull

if  ! git clone https://aur.archlinux.org/$1.git; then
    # if  cloning throws an error check the HTTP status of the package's aur page & exit
    comm -23 <(pacman -Qqm | sort) <(curl https://aur.archlinux.org/packages.gz | gzip -cd | sort)
    echo "git clone failed"
    exit
fi


cd $1

# verify PKGBUILD manually
less PKGBUILD
echo "Continue? y/n"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

# check if gpg signature is detached & run the correct command
#https://wiki.archlinux.org/title/GnuPG#Verify_a_signature
#echo "detached or attached?"
# run this in the same directory as the data file & signature file
#gpg --verify some-iso-file.iso.sig # where some-iso-file.iso is in the same directory
# attached gpg --verify some-iso-file.iso.sig


# make & install the package
makepkg --syncdeps --install --clean

# only needed if --install flag is not passed to makepkg
# pacman -U $1*.pkg.tar.zst
