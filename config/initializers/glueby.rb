# Edit configuration for connection to tapyrus core
Tapyrus.chain_params = :dev
config = {adapter: 'core', schema: 'http', host: '127.0.0.1', port: 12381, user: 'rpcuser', password: 'rpcpassword'}
Glueby::Wallet.configure(config)
