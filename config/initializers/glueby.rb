# Edit configuration for connection to tapyrus core
Tapyrus.chain_params = :dev
config = {adapter: 'activerecord', schema: 'http', host: 'workshop202107_tapyrusd', port: 12381, user: 'rpcuser', password: 'rpcpassword'}
Glueby::Wallet.configure(config)
