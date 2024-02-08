#Save and shutdown the server
function save_and_shutdown_server() {
    rcon 'broadcast Server-shutdown-was-requested-init-saving'
    rcon 'save'
    rcon 'broadcast Done-saving-server-shuts-down-now'
}
