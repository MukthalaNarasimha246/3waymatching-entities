-- Table: public.hypotus_bbox
CREATE TABLE IF NOT EXISTS public.hypotus_bbox (
    id SERIAL PRIMARY KEY,
    image_path VARCHAR(255),
    bbox TEXT
);

-- Table: public.image_classification_hypotus
CREATE TABLE IF NOT EXISTS public.image_classification_hypotus (
    id SERIAL PRIMARY KEY,
    claim_id VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL,
    blob_image TEXT NOT NULL,
    top_label VARCHAR(100) NOT NULL,
    confidence NUMERIC(5,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    batchid BIGINT,
    mapping_id VARCHAR
);

-- Table: public.image_duplicates
CREATE TABLE IF NOT EXISTS public.image_duplicates (
    id SERIAL PRIMARY KEY,
    reference_image TEXT,
    target_image TEXT,
    feature_similarity NUMERIC,
    text_similarity NUMERIC,
    reference_tampering_score NUMERIC,
    target_tampering_score NUMERIC,
    duplicate_status TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pdf_ref_id VARCHAR
);

-- Table: public.invoice_asset_details
CREATE TABLE IF NOT EXISTS public.invoice_asset_details (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER,
    material_code VARCHAR(100),
    chassis_number VARCHAR(100),
    engine_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: public.invoice_bank_details
CREATE TABLE IF NOT EXISTS public.invoice_bank_details (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER,
    account_holder_name VARCHAR(255),
    bank_name VARCHAR(255),
    account_number VARCHAR(100),
    ifsc_code VARCHAR(20),
    branch_name VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: public.invoice_buyer_details
CREATE TABLE IF NOT EXISTS public.invoice_buyer_details (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER,
    buyer_company_name VARCHAR(255),
    buyer_address TEXT,
    buyer_state VARCHAR(100),
    buyer_state_code VARCHAR(10),
    buyer_gstin VARCHAR(100),
    buyer_pan VARCHAR(20),
    buyer_cin VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_buyer_details_invoice_id_fkey
        FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id)
        ON DELETE CASCADE
);

-- Table: public.invoice_check_list
CREATE TABLE IF NOT EXISTS public.invoice_check_list (
    id SERIAL PRIMARY KEY,
    pdf_ref_id INTEGER,
    invoice_number TEXT,
    invoice_date TEXT,
    vendor_name TEXT,
    address TEXT,
    supplier_gstin TEXT,
    buyer_gstin TEXT,
    supplier_pan TEXT,
    gstin_pan TEXT,
    invoice_sum_amount_total_amount NUMERIC(15,2),
    is_duplicate BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: public.invoice_details
CREATE TABLE IF NOT EXISTS public.invoice_details (
    invoice_id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(100),
    invoice_date DATE,
    total_amount NUMERIC(20,2),
    po_ref VARCHAR(100),
    batch_id VARCHAR(100),
    company_name VARCHAR,
    vendor_name VARCHAR(255),
    supplier_gstin VARCHAR(15),
    buyer_gstin VARCHAR(15),
    delivery_location VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: public.invoice_lineitems
CREATE TABLE IF NOT EXISTS public.invoice_lineitems (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(255),
    hsn VARCHAR(50),
    quantity NUMERIC(15,2),
    uom VARCHAR(50),
    rate_incl_of_tax NUMERIC(15,2),
    unit_price NUMERIC(15,2),
    total_retail_price NUMERIC(15,2),
    total_taxable_amount NUMERIC(15,2),
    total_value NUMERIC(20,2),
    discount VARCHAR DEFAULT '0',
    invoice_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_lineitems_invoice_id_fkey
        FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id)
);

-- Table: public.invoice_shipping_details
CREATE TABLE IF NOT EXISTS public.invoice_shipping_details (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER,
    ship_to_company_name VARCHAR(255),
    ship_to_address TEXT,
    ship_to_state VARCHAR(100),
    ship_to_state_code VARCHAR(50),
    ship_to_gstin VARCHAR(50),
    ship_to_pan VARCHAR(50),
    ship_to_cin VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: public.invoice_summary
CREATE TABLE IF NOT EXISTS public.invoice_summary (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER,
    total_discount_value NUMERIC(15,2),
    total_quantity NUMERIC(15,2),
    total_taxable_amount NUMERIC(15,2),
    tcs_rate VARCHAR(10),
    taxable_value NUMERIC(15,2),
    total_cgst_amount NUMERIC(15,2),
    total_sgst_amount NUMERIC(15,2),
    total_tax_amount NUMERIC(15,2),
    total_invoice_value NUMERIC(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_summary_invoice_id_fkey FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id)
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

-- Table: public.invoice_supplier_details
CREATE TABLE IF NOT EXISTS public.invoice_supplier_details (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER,
    pan_supplier VARCHAR(20),
    gstin_supplier VARCHAR(50),
    udyam_regno VARCHAR(100),
    state VARCHAR(100),
    state_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    supplier_name VARCHAR(255),
    supplier_address TEXT,
    CONSTRAINT invoice_supplier_details_invoice_id_fkey FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id)
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

-- Table: public.mrn_buyer_details
CREATE TABLE IF NOT EXISTS public.mrn_buyer_details (
    id SERIAL PRIMARY KEY,
    mrn_id INTEGER,
    received_at TEXT,
    received_address TEXT,
    gstin_receiving_party VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mrn_buyer_details_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id)
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

-- Table: public.mrn_details
CREATE TABLE IF NOT EXISTS public.mrn_details (
    id SERIAL PRIMARY KEY,
    mrn_number VARCHAR(100) UNIQUE,
    mrn_date DATE,
    po_reference_number VARCHAR(100),
    po_date DATE,
    ref_invoice_number VARCHAR(100),
    ref_invoice_date DATE,
    info TEXT,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vendor_name VARCHAR(255),
    supplier_gstin VARCHAR(15),
    buyer_gstin VARCHAR(15),
    delivery_location VARCHAR(255),
    total_amount VARCHAR(255)
);

-- Table: public.mrn_lineitems
CREATE TABLE IF NOT EXISTS public.mrn_lineitems (
    item_id SERIAL PRIMARY KEY,
    mrn_id INTEGER,
    item_name TEXT,
    received_quantity NUMERIC(10,2),
    hsn_sac VARCHAR(50),
    uom VARCHAR(20),
    mrp NUMERIC(15,2),
    unit_price NUMERIC(15,2),
    discount NUMERIC(15,2),
    gross_amount NUMERIC(15,2),
    net_amount NUMERIC(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gst_rate VARCHAR,
    CONSTRAINT mrn_lineitems_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id)
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

-- Table: public.mrn_summary
CREATE TABLE IF NOT EXISTS public.mrn_summary (
    id SERIAL PRIMARY KEY,
    mrn_id INTEGER,
    cgst NUMERIC(15,2),
    sgst NUMERIC(15,2),
    igst NUMERIC(15,2),
    gst_amount NUMERIC(15,2),
    cess NUMERIC(15,2),
    total_qty NUMERIC(10,2),
    total_value NUMERIC(20,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mrn_summary_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id)
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

-- Table: mrn_supplier_details
CREATE TABLE IF NOT EXISTS public.mrn_supplier_details (
    id SERIAL PRIMARY KEY,
    mrn_id INTEGER,
    supplier_name TEXT,
    supplier_address TEXT,
    gstin_supplier VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mrn_supplier_details_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id) ON DELETE CASCADE
);

-- Table: pdf_conversion_hypotus
CREATE TABLE IF NOT EXISTS public.pdf_conversion_hypotus (
    id SERIAL PRIMARY KEY,
    claim_id VARCHAR(255) NOT NULL,
    num_pdfs INTEGER NOT NULL,
    num_images INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    batchid BIGINT
);

-- Table: po_details
CREATE TABLE IF NOT EXISTS public.po_details (
    po_id SERIAL PRIMARY KEY,
    po_number VARCHAR(100),
    po_date DATE,
    total_amount NUMERIC(15,2),
    vendor_ref VARCHAR(255),
    delivery_terms TEXT,
    payment_term TEXT,
    shipment_mode VARCHAR(100),
    warranty_period VARCHAR(100),
    delivery_period VARCHAR(100),
    contact_person VARCHAR(100),
    mobile VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    item_code VARCHAR,
    vendor_name VARCHAR(255),
    supplier_gstin VARCHAR(15),
    buyer_gstin VARCHAR(15),
    delivery_location VARCHAR(255)
);

-- Table: po_billto
CREATE TABLE IF NOT EXISTS public.po_billto (
    id SERIAL PRIMARY KEY,
    po_id INTEGER,
    bill_to VARCHAR(255),
    billing_address TEXT,
    gstin_buyer VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_billto_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) ON DELETE CASCADE
);

-- Table: po_lineitems
CREATE TABLE IF NOT EXISTS public.po_lineitems (
    item_id SERIAL PRIMARY KEY,
    po_id INTEGER NOT NULL,
    item_name VARCHAR(255),
    oem_part_code VARCHAR(100),
    quantity NUMERIC(15,2),
    uom VARCHAR(50),
    unit_price NUMERIC(15,2),
    discount NUMERIC(15,2),
    taxable NUMERIC(15,2),
    gst_rate NUMERIC(5,2),
    gst_amount NUMERIC(15,2),
    billable_value NUMERIC(15,2),
    total_qty NUMERIC(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: po_shipping_details
CREATE TABLE IF NOT EXISTS public.po_shipping_details (
    id SERIAL PRIMARY KEY,
    po_id INTEGER,
    ship_to VARCHAR(255),
    shipping_address TEXT,
    gstin_buyer VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_shipping_details_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) ON DELETE CASCADE
);

-- Table: po_summary
CREATE TABLE IF NOT EXISTS public.po_summary (
    id SERIAL PRIMARY KEY,
    po_id INTEGER NOT NULL,
    total_qty NUMERIC(15,2),
    total_rate NUMERIC(15,2),
    total_discount NUMERIC(15,2),
    total_taxable_amount NUMERIC(15,2),
    total_gst_amt NUMERIC(15,2),
    total_billable_value NUMERIC(15,2),
    charges_and_deductions NUMERIC(15,2),
    total_purchase_order_amount NUMERIC(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: po_supplier_details
CREATE TABLE IF NOT EXISTS public.po_supplier_details (
    id SERIAL PRIMARY KEY,
    po_id INTEGER,
    supplier_name VARCHAR(255),
    supplier_code VARCHAR(255),
    gstin_supplier VARCHAR(50),
    supplier_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_supplier_details_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) ON DELETE CASCADE
);

-- Table: po_terms_conditions
CREATE TABLE IF NOT EXISTS public.po_terms_conditions (
    id SERIAL PRIMARY KEY,
    po_id INTEGER,
    terms_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_terms_conditions_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) ON DELETE CASCADE
);

-- Table: purchase_order_details
CREATE TABLE IF NOT EXISTS public.purchase_order_details (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(100) NOT NULL,
    po_no VARCHAR(100) NOT NULL UNIQUE,
    po_date DATE,
    vendor_ref VARCHAR(150),
    delivery_terms VARCHAR(255),
    payment_terms VARCHAR(255),
    shipment_mode VARCHAR(150),
    warranty_period VARCHAR(150),
    delivery_period VARCHAR(150),
    contact_person VARCHAR(150),
    mobile_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: rao_details
CREATE TABLE IF NOT EXISTS public.rao_details (
    rao_id SERIAL PRIMARY KEY,
    rao_number VARCHAR(100),
    rao_date DATE,
    po_reference_number VARCHAR(100),
    po_date DATE,
    ref_invoice_number VARCHAR(100),
    ref_invoice_date DATE,
    document_title TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Table: rao_lineitems
CREATE TABLE IF NOT EXISTS public.rao_lineitems (
    item_id SERIAL PRIMARY KEY,
    rao_id INTEGER,
    item_name TEXT,
    received_quantity NUMERIC(10,2),
    hsn_sac VARCHAR(50),
    unit_price NUMERIC(15,2),
    discount NUMERIC(15,2),
    gst_rate NUMERIC(5,2),
    total_value NUMERIC(20,2),
    engine_no VARCHAR(100),
    chasis_no VARCHAR(100),
    serial_no VARCHAR(100),
    asset_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rao_lineitems_rao_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) ON DELETE CASCADE
);

-- Table: rao_receivedat
CREATE TABLE IF NOT EXISTS public.rao_receivedat (
    id SERIAL PRIMARY KEY,
    rao_id INTEGER,
    received_date DATE,
    received_at TEXT,
    received_address TEXT,
    gstin_receiving_party VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rao_receivedat_grn_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) ON DELETE CASCADE
);

-- Table: rao_summary
CREATE TABLE IF NOT EXISTS public.rao_summary (
    id SERIAL PRIMARY KEY,
    rao_id INTEGER,
    total_discount NUMERIC(15,2),
    cgst NUMERIC(15,2),
    sgst NUMERIC(15,2),
    igst NUMERIC(15,2),
    gst_amount NUMERIC(15,2),
    cess NUMERIC(15,2),
    total_qty NUMERIC(15,2),
    total_value NUMERIC(20,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gross_amount VARCHAR,
    sub_total VARCHAR,
    CONSTRAINT rao_summary_rao_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) ON DELETE CASCADE
);

-- Table: rao_supplier_details
CREATE TABLE IF NOT EXISTS public.rao_supplier_details (
    id SERIAL PRIMARY KEY,
    rao_id INTEGER,
    supplier_name TEXT,
    supplier_address TEXT,
    gstin_supplier VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rao_supplier_details_rao_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) ON DELETE CASCADE
);


