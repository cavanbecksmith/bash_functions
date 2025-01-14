alias nvm_ls="nvm ls"

migration_date() {
  # Y_m_d_His
  local dt=$(date '+%Y_%m_%d_%H%M%S');
  echo "$dt"
}

folder_date() {
  local dt=$(date '+%d_%m_%Y_%H%M%S');
  echo "$dt"
}