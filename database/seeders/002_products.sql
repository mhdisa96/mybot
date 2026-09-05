INSERT INTO products(code,name,category,provider,cost_price,selling_price,status,digiflazz_sku) VALUES
('TSEL10','Telkomsel 10K','PULSA','Telkomsel',9500,11000,'ACTIVE','tsel10'),
('TSEL25','Telkomsel 25K','PULSA','Telkomsel',24000,27000,'ACTIVE','tsel25'),
('XL10','XL 10K','PULSA','XL',9500,11000,'ACTIVE','xl10'),
('PLN20','Token PLN 20K','PLN_TOKEN','PLN',19700,21000,'ACTIVE','pln20'),
('DANA20','DANA 20K','E_WALLET','DANA',20000,22000,'ACTIVE','dana20'),
('OVO20','OVO 20K','E_WALLET','OVO',20000,22000,'ACTIVE','ovo20')
ON CONFLICT (code) DO NOTHING;
