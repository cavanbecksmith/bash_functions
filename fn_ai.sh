rai() {
    local agent="${CODING_AGENT:-claude}"
    repos && "$agent"
}
