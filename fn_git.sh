
function autocommit() {
	git add --all
	git commit -m "AUTO COMMIT"
	git push
}

function git_reset(){
    read -p "Sure u want to reset commits? (y/n): " response
if [[ "$response" == "y" || "$response" == "Y" ]]; then
  git reset --hard HEAD
else
    echo "goodbye"
fi

}