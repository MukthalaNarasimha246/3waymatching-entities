import psycopg2
from psycopg2 import sql

MASTER_DB = "test_1"
MASTER_DB_URL = {
    "dbname": MASTER_DB,
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432
}

ADMIN_DB_URL = {
    "dbname": "postgres",  # Connect to postgres for admin commands
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432
}

def apply_schema_to_target_db(db_name: str):
    db_url = {
        "dbname": db_name,
        "user": "postgres",
        "password": "postgres",
        "host": "localhost",
        "port": 5432
    }

    schema_sql = """
   -- Table: public.hypotus_bbox
CREATE TABLE IF NOT EXISTS public.hypotus_bbox (
    id SERIAL PRIMARY KEY,
    image_path VARCHAR(255),
    bbox TEXT
);

CREATE TABLE invoice_duplicates_check (
    id SERIAL PRIMARY KEY,
    pdf_ref_id VARCHAR(255) NOT NULL,
    invoice_number VARCHAR(100),
    invoice_date DATE,
    vendor_name VARCHAR(255),
    address TEXT,
    supplier_gstin VARCHAR(20),
    buyer_gstin VARCHAR(20),
    supplier_pan VARCHAR(20),
    gstin_pan VARCHAR(20),
    invoice_sum_amount_total_amount NUMERIC(15, 2),
    is_duplicate BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    mapping_id VARCHAR,
    is_hitl BOOLEAN DEFAULT FALSE
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
    similarity_image TEXT,
    similarity_status TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pdf_ref_id VARCHAR,
    review_status VARCHAR(100),  
    review_remark TEXT    

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
    udyam_reg VARCHAR(100),
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
    batchid BIGINT,
    review_status VARCHAR(50)
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

CREATE TABLE progress_files (
    batch_id VARCHAR(255) PRIMARY KEY,
    processed_count INT DEFAULT 0,
    total_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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






CREATE OR REPLACE FUNCTION public.get_3_way_checklist(
	invoice_id_input integer)
    RETURNS TABLE(field_name text, po_present text, invoice_present text, mrn_present text, match_status text, notes text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
  RETURN QUERY
  WITH lineitem_presence AS (
    SELECT
        -- From PO
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.item_name IS NOT NULL
        ) AS po_item_name,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.oem_part_code IS NOT NULL
        ) AS po_item_code,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.quantity IS NOT NULL
        ) AS po_quantity,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.uom IS NOT NULL
        ) AS po_uom,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.unit_price IS NOT NULL
        ) AS po_unit_price,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.discount IS NOT NULL
        ) AS po_discount,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.unit_price IS NOT NULL
        ) AS po_tax_rate,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.taxable IS NOT NULL
        ) AS po_tax_amount,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN po_lineitems po ON po.po_id = pdet.po_id
            WHERE idet.invoice_id = invoice_id_input AND po.billable_value IS NOT NULL
        ) AS po_total_value,

        -- From Invoice
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.item_name IS NOT NULL
        ) AS inv_item_name,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.hsn IS NOT NULL
        ) AS inv_item_code,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.quantity IS NOT NULL
        ) AS inv_quantity,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.uom IS NOT NULL
        ) AS inv_uom,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.unit_price IS NOT NULL
        ) AS inv_unit_price,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.discount IS NOT NULL
        ) AS inv_discount,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.total_retail_price IS NOT NULL
        ) AS inv_tax_rate,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.total_taxable_amount IS NOT NULL
        ) AS inv_tax_amount,
        EXISTS (
            SELECT 1 FROM invoice_lineitems inv WHERE inv.invoice_id = invoice_id_input AND inv.total_value IS NOT NULL
        ) AS inv_total_value,

        -- From MRN
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN mrn_details md ON md.po_reference_number = pdet.po_number
            JOIN mrn_lineitems m ON m.mrn_id = md.id
            WHERE idet.invoice_id = invoice_id_input AND m.item_name IS NOT NULL
        ) AS mrn_item_name,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN mrn_details md ON md.po_reference_number = pdet.po_number
            JOIN mrn_lineitems m ON m.mrn_id = md.id
            WHERE idet.invoice_id = invoice_id_input AND m.hsn_sac IS NOT NULL
        ) AS mrn_item_code,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN mrn_details md ON md.po_reference_number = pdet.po_number
            JOIN mrn_lineitems m ON m.mrn_id = md.id
            WHERE idet.invoice_id = invoice_id_input AND m.received_quantity IS NOT NULL
        ) AS mrn_quantity,
        EXISTS (
            SELECT 1 FROM invoice_details idet
            JOIN po_details pdet ON idet.po_ref = pdet.po_number
            JOIN mrn_details md ON md.po_reference_number = pdet.po_number
            JOIN mrn_lineitems m ON m.mrn_id = md.id
            WHERE idet.invoice_id = invoice_id_input AND m.uom IS NOT NULL
        ) AS mrn_uom
  )
  SELECT 
    t.field_name,
    CASE WHEN t.po THEN 'Yes' ELSE 'No' END AS po_present,
    CASE WHEN t.inv THEN 'Yes' ELSE 'No' END AS invoice_present,
    CASE 
      WHEN t.mrn IS NULL THEN 'N/A'
      WHEN t.mrn THEN 'Yes' ELSE 'No'
    END AS mrn_present,
    CASE 
      WHEN t.po AND t.inv AND (t.mrn OR t.mrn IS NULL) THEN '✔️'
      ELSE '❌'
    END AS match_status,
    CASE
      WHEN NOT t.po AND NOT t.inv AND NOT COALESCE(t.mrn, false) THEN 'Missing in all'
      WHEN NOT t.po THEN 'Missing in PO'
      WHEN NOT t.inv THEN 'Missing in Invoice'
      WHEN t.mrn IS NOT NULL AND NOT t.mrn THEN 'Missing in MRN'
      WHEN t.mrn IS NULL THEN 'Not tracked in MRN'
      ELSE 'Present in all'
    END AS notes
  FROM lineitem_presence,
  LATERAL (
    VALUES
      ('Item Description', po_item_name, inv_item_name, mrn_item_name),
      ('Item Code / HSN/SAC Code', po_item_code, inv_item_code, mrn_item_code),
      ('Quantity', po_quantity, inv_quantity, mrn_quantity),
      ('UOM (Unit of Measure)', po_uom, inv_uom, mrn_uom),
      ('Unit Price', po_unit_price, inv_unit_price, NULL),
      ('Discounts', po_discount, inv_discount, NULL),
      ('Tax Rates (CGST/SGST/IGST)', po_tax_rate, inv_tax_rate, NULL),
      ('Tax Amounts', po_tax_amount, inv_tax_amount, NULL),
      ('Total Amount per Item', po_total_value, inv_total_value, NULL)
  ) AS t(field_name, po, inv, mrn);
END;
$BODY$;


CREATE OR REPLACE FUNCTION public.get_3way_match_results(
	invoice_id_input integer)
    RETURNS TABLE(item_name text, po_qty numeric, invoice_qty numeric, mrn_qty numeric, po_invoice_match_percent numeric, invoice_mrn_match_percent numeric, match_status text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT
        po.item_name::text,
        po.quantity::numeric AS po_qty,
        COALESCE(inv_matched.quantity, 0)::numeric AS invoice_qty,
        COALESCE(mrn_matched.received_quantity, 0)::numeric AS mrn_qty,

        ROUND(
            CASE 
                WHEN GREATEST(po.quantity, COALESCE(inv_matched.quantity, 0)) > 0 THEN 
                    100.0 * LEAST(po.quantity, COALESCE(inv_matched.quantity, 0)) / GREATEST(po.quantity, COALESCE(inv_matched.quantity, 0))
                ELSE 0 
            END, 2
        ) AS po_invoice_match_percent,

        ROUND(
            CASE 
                WHEN GREATEST(COALESCE(inv_matched.quantity, 0), COALESCE(mrn_matched.received_quantity, 0)) > 0 THEN 
                    100.0 * LEAST(COALESCE(inv_matched.quantity, 0), COALESCE(mrn_matched.received_quantity, 0)) / GREATEST(COALESCE(inv_matched.quantity, 0), COALESCE(mrn_matched.received_quantity, 0))
                ELSE 0 
            END, 2
        ) AS invoice_mrn_match_percent,

        CASE
            WHEN inv_matched.item_name IS NULL THEN 'Missing in Invoice'
            WHEN mrn_matched.item_name IS NULL THEN 'Missing in MRN'
            WHEN COALESCE(inv_matched.quantity, 0) > po.quantity THEN 'Over-Invoiced'
            WHEN COALESCE(inv_matched.quantity, 0) < po.quantity THEN 'Under-Invoiced'
            WHEN po.quantity = COALESCE(inv_matched.quantity, 0) AND COALESCE(inv_matched.quantity, 0) = COALESCE(mrn_matched.received_quantity, 0) THEN 'Perfect Match'
            ELSE 'Mismatch'
        END::text AS match_status

    FROM
        po_details pod
    JOIN
        po_lineitems po ON po.po_id = pod.po_id

    LEFT JOIN
        invoice_details idet ON idet.po_ref = pod.po_number AND idet.invoice_id = invoice_id_input

    LEFT JOIN LATERAL (
        SELECT *
        FROM invoice_lineitems inv
        WHERE inv.invoice_id = idet.invoice_id
        ORDER BY similarity(inv.item_name, po.item_name) DESC
        LIMIT 1
    ) inv_matched ON similarity(inv_matched.item_name, po.item_name) > 0.1

    LEFT JOIN
        mrn_details mdet ON mdet.mrn_number = pod.po_number

    LEFT JOIN LATERAL (
        SELECT *
        FROM mrn_lineitems mrn
        WHERE mrn.mrn_id = mdet.id
        ORDER BY similarity(mrn.item_name, po.item_name) DESC
        LIMIT 1
    ) mrn_matched ON similarity(mrn_matched.item_name, po.item_name) > 0.1;

END;
$BODY$;

CREATE OR REPLACE FUNCTION public.get_combined_transaction_summary(
	invoice_id_input integer)
    RETURNS TABLE(po_number character varying, invoice_id integer, invoice_number character varying, mrn_number character varying, po_total_qty numeric, po_total_rate numeric, po_total_discount numeric, po_taxable numeric, po_total_gst numeric, po_total_billable numeric, po_total_value numeric, invoice_total_discount numeric, invoice_total_qty numeric, invoice_taxable numeric, invoice_cgst numeric, invoice_sgst numeric, invoice_total_tax numeric, invoice_total_value numeric, mrn_total_qty numeric, mrn_cgst numeric, mrn_sgst numeric, mrn_igst numeric, mrn_total_gst numeric, mrn_total_value numeric) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT
        pod.po_number,
        ind.invoice_id,
        ind.invoice_number,
        mrnd.mrn_number,

        pos.total_qty,
        pos.total_rate,
        pos.total_discount,
        pos.total_taxable_amount,
        pos.total_gst_amt,
        pos.total_billable_value,
        pos.total_purchase_order_amount,

        invs.total_discount_value,
        invs.total_quantity,
        invs.total_taxable_amount,
        invs.total_cgst_amount,
        invs.total_sgst_amount,
        invs.total_tax_amount,
        invs.total_invoice_value,

        mrns.total_qty,
        mrns.cgst,
        mrns.sgst,
        mrns.igst,
        mrns.gst_amount,
        mrns.total_value

    FROM invoice_details ind
    LEFT JOIN invoice_summary invs ON invs.invoice_id = ind.invoice_id
    LEFT JOIN po_details pod ON pod.po_number = ind.po_ref
    LEFT JOIN po_summary pos ON pos.po_id = pod.po_id
    LEFT JOIN mrn_details mrnd ON mrnd.po_reference_number = pod.po_number
    LEFT JOIN mrn_summary mrns ON mrns.mrn_id = mrnd.id
    WHERE ind.invoice_id = invoice_id_input;
END;
$BODY$;
CREATE OR REPLACE FUNCTION public.get_invoice_po_match_results(
	invoice_id_input integer)
    RETURNS TABLE(inv_id integer, po_id integer, invoice_item text, po_item text, item_name_match_percent numeric, invoice_qty numeric, po_qty numeric, quantity_match_percent numeric, total_taxable_amount numeric, po_unit_price numeric, unit_price_match_percent numeric, invoice_total_value numeric, po_total_value numeric, total_value_match_percent numeric, match_status text, mismatch_reason text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY

    -- Matches from invoice side
    SELECT
        inv.invoice_id::integer AS inv_id,
        po.po_id::integer,
        
        inv.item_name::text AS invoice_item,
        po.item_name::text AS po_item,
        ROUND((similarity(inv.item_name, po.item_name) * 100)::numeric, 2) AS item_name_match_percent,

        inv.quantity::numeric AS invoice_qty,
        po.quantity::numeric AS po_qty,
        ROUND(
            CASE 
                WHEN GREATEST(inv.quantity, po.quantity) > 0 THEN 
                    (100.0 * LEAST(inv.quantity, po.quantity) / GREATEST(inv.quantity, po.quantity))::numeric
                ELSE 0 
            END, 2
        ) AS quantity_match_percent,

        inv.total_taxable_amount::numeric,
        po.unit_price::numeric AS po_unit_price,
        ROUND(
            CASE 
                WHEN GREATEST(inv.total_taxable_amount, po.unit_price) > 0 THEN 
                    (100.0 * LEAST(inv.total_taxable_amount, po.unit_price) / GREATEST(inv.total_taxable_amount, po.unit_price))::numeric
                ELSE 0 
            END, 2
        ) AS unit_price_match_percent,

        inv.total_value::numeric AS invoice_total_value,
        po.taxable::numeric AS po_total_value,
        ROUND(
            CASE 
                WHEN GREATEST(inv.total_value, po.taxable) > 0 THEN 
                    (100.0 * LEAST(inv.total_value, po.taxable) / GREATEST(inv.total_value, po.taxable))::numeric
                ELSE 0 
            END, 2
        ) AS total_value_match_percent,

        CASE 
            WHEN inv.quantity = po.quantity
                 AND inv.total_value = po.taxable
            THEN 'Matched'
            ELSE 'Not Match'
        END AS match_status,

        -- Reason for mismatch (excluding item name)
        TRIM(BOTH ', ' FROM CONCAT(
            CASE WHEN inv.quantity != po.quantity THEN 'Quantity mismatch, ' ELSE '' END,
            CASE WHEN inv.total_value != po.taxable THEN 'Total Value mismatch, ' ELSE '' END
        )) AS mismatch_reason

    FROM
        invoice_lineitems inv
    JOIN
        invoice_details idet ON inv.invoice_id = idet.invoice_id
    JOIN
        po_details pdet ON idet.po_ref = pdet.po_number
    LEFT JOIN LATERAL (
        SELECT po.*
        FROM po_lineitems po
        WHERE po.po_id = pdet.po_id
          AND similarity(inv.item_name, po.item_name) > 0.1
        ORDER BY similarity(inv.item_name, po.item_name) DESC
        LIMIT 1
    ) po ON true
    WHERE inv.invoice_id = invoice_id_input

    UNION

    -- Matches from PO side not found above
    SELECT
        NULL::integer AS inv_id,
        po.po_id::integer,
        
        NULL::text AS invoice_item,
        po.item_name::text AS po_item,
        NULL::numeric AS item_name_match_percent,

        NULL::numeric AS invoice_qty,
        po.quantity::numeric AS po_qty,
        NULL::numeric AS quantity_match_percent,

        NULL::numeric AS total_taxable_amount,
        po.unit_price::numeric AS po_unit_price,
        NULL::numeric AS unit_price_match_percent,

        NULL::numeric AS invoice_total_value,
        po.taxable::numeric AS po_total_value,
        NULL::numeric AS total_value_match_percent,

        'No Matching Invoice Item'::text AS match_status,
        'Invoice line item not found for PO item'::text AS mismatch_reason

    FROM
        po_details pdet
    JOIN
        po_lineitems po ON po.po_id = pdet.po_id
    LEFT JOIN LATERAL (
        SELECT inv2.*
        FROM invoice_details idet2
        JOIN invoice_lineitems inv2 ON inv2.invoice_id = idet2.invoice_id
        WHERE idet2.po_ref = pdet.po_number
          AND similarity(inv2.item_name, po.item_name) > 0.1
        ORDER BY similarity(inv2.item_name, po.item_name) DESC
        LIMIT 1
    ) inv2 ON true
    WHERE inv2.invoice_id IS NULL
      AND pdet.po_number = (
          SELECT idet.po_ref FROM invoice_details idet WHERE idet.invoice_id = invoice_id_input
      )

    ORDER BY match_status DESC, item_name_match_percent DESC NULLS LAST;
END;
$BODY$;

CREATE OR REPLACE FUNCTION public.get_invoice_po_match_results_v2(
	invoice_id_input integer)
    RETURNS TABLE(inv_id integer, po_id integer, invoice_item text, po_item text, item_name_match_percent numeric, invoice_qty numeric, po_qty numeric, quantity_match_percent numeric, total_taxable_amount numeric, po_unit_price numeric, unit_price_match_percent numeric, invoice_total_value numeric, po_total_value numeric, total_value_match_percent numeric, match_status text, mismatch_reason text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY

    WITH aggregated_invoice_items AS (
        SELECT
            inv.invoice_id,
            inv.item_name,
            SUM(inv.quantity) AS quantity,
            SUM(inv.total_taxable_amount) AS total_taxable_amount,
            SUM(inv.total_value) AS total_value
        FROM invoice_lineitems inv
        WHERE inv.invoice_id = invoice_id_input
        GROUP BY inv.invoice_id, inv.item_name
    )

    -- Matches from invoice side
    SELECT
        inv.invoice_id::integer AS inv_id,
        po.po_id::integer,
        
        inv.item_name::text AS invoice_item,
        po.item_name::text AS po_item,
        ROUND((similarity(inv.item_name, po.item_name) * 100)::numeric, 2) AS item_name_match_percent,

        inv.quantity::numeric AS invoice_qty,
        po.quantity::numeric AS po_qty,
        ROUND(
            CASE 
                WHEN GREATEST(inv.quantity, po.quantity) > 0 THEN 
                    (100.0 * LEAST(inv.quantity, po.quantity) / GREATEST(inv.quantity, po.quantity))::numeric
                ELSE 0 
            END, 2
        ) AS quantity_match_percent,

        inv.total_taxable_amount::numeric,
        po.unit_price::numeric AS po_unit_price,
        ROUND(
            CASE 
                WHEN GREATEST(inv.total_taxable_amount, po.unit_price) > 0 THEN 
                    (100.0 * LEAST(inv.total_taxable_amount, po.unit_price) / GREATEST(inv.total_taxable_amount, po.unit_price))::numeric
                ELSE 0 
            END, 2
        ) AS unit_price_match_percent,

        inv.total_value::numeric AS invoice_total_value,
        po.taxable::numeric AS po_total_value,
        ROUND(
            CASE 
                WHEN GREATEST(inv.total_value, po.taxable) > 0 THEN 
                    (100.0 * LEAST(inv.total_value, po.taxable) / GREATEST(inv.total_value, po.taxable))::numeric
                ELSE 0 
            END, 2
        ) AS total_value_match_percent,

        CASE 
            WHEN inv.quantity = po.quantity
                 AND inv.total_value = po.taxable
            THEN 'Matched'
            ELSE 'Not Match'
        END AS match_status,

        -- Reason for mismatch (excluding item name)
        TRIM(BOTH ', ' FROM CONCAT(
            CASE WHEN inv.quantity != po.quantity THEN 'Quantity mismatch, ' ELSE '' END,
            CASE WHEN inv.total_value != po.taxable THEN 'Total Value mismatch, ' ELSE '' END
        )) AS mismatch_reason

    FROM
        aggregated_invoice_items inv
    JOIN
        invoice_details idet ON inv.invoice_id = idet.invoice_id
    JOIN
        po_details pdet ON idet.po_ref = pdet.po_number
    LEFT JOIN LATERAL (
        SELECT po.*
        FROM po_lineitems po
        WHERE po.po_id = pdet.po_id
          AND similarity(inv.item_name, po.item_name) > 0.1
        ORDER BY similarity(inv.item_name, po.item_name) DESC
        LIMIT 1
    ) po ON true

    UNION

    -- Matches from PO side not found above
    SELECT
        NULL::integer AS inv_id,
        po.po_id::integer,
        
        NULL::text AS invoice_item,
        po.item_name::text AS po_item,
        NULL::numeric AS item_name_match_percent,

        NULL::numeric AS invoice_qty,
        po.quantity::numeric AS po_qty,
        NULL::numeric AS quantity_match_percent,

        NULL::numeric AS total_taxable_amount,
        po.unit_price::numeric AS po_unit_price,
        NULL::numeric AS unit_price_match_percent,

        NULL::numeric AS invoice_total_value,
        po.taxable::numeric AS po_total_value,
        NULL::numeric AS total_value_match_percent,

        'No Matching Invoice Item'::text AS match_status,
        'Invoice line item not found for PO item'::text AS mismatch_reason

    FROM
        po_details pdet
    JOIN
        po_lineitems po ON po.po_id = pdet.po_id
    LEFT JOIN LATERAL (
        SELECT inv_agg.*
        FROM invoice_details idet2
        JOIN aggregated_invoice_items inv_agg ON inv_agg.invoice_id = idet2.invoice_id
        WHERE idet2.po_ref = pdet.po_number
          AND similarity(inv_agg.item_name, po.item_name) > 0.1
        ORDER BY similarity(inv_agg.item_name, po.item_name) DESC
        LIMIT 1
    ) inv2 ON true
    WHERE inv2.invoice_id IS NULL
      AND pdet.po_number = (
          SELECT idet.po_ref FROM invoice_details idet WHERE idet.invoice_id = invoice_id_input
      )

    ORDER BY match_status DESC, item_name_match_percent DESC NULLS LAST;

END;
$BODY$;

CREATE OR REPLACE FUNCTION public.get_invoice_po_summary(
	invoice_id_input integer)
    RETURNS TABLE(invoice_number text, po_ref text, po_number text, invoice_amount numeric, po_amount numeric, amount_match_percentage numeric, po_number_match text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT
        i.invoice_number::text,
        i.po_ref::text,
        po.po_number::text,
        i.total_amount::numeric AS invoice_amount,
        po.total_amount::numeric AS po_amount,
        CASE
            WHEN po.total_amount IS NOT NULL AND po.total_amount != 0 THEN
                ROUND(100.0 * LEAST(i.total_amount, po.total_amount) / GREATEST(i.total_amount, po.total_amount), 2)
            ELSE 0
        END AS amount_match_percentage,
        CASE
            WHEN i.po_ref = po.po_number THEN 'YES'
            ELSE 'NO'
        END::text AS po_number_match
    FROM
        invoice_details i
    LEFT JOIN
        po_details po ON i.po_ref = po.po_number
    WHERE
        i.invoice_id = invoice_id_input;
END;
$BODY$;

CREATE OR REPLACE FUNCTION public.get_invoice_with_po_details(
	)
    RETURNS TABLE(invoice_id integer, invoice_number character varying, invoice_date date, invoice_total numeric, po_ref character varying, batch_id character varying, company_name character varying, invoice_created_at timestamp without time zone, po_id integer, po_number character varying, po_date date, po_total numeric, vendor_ref character varying, delivery_terms text, payment_term text, shipment_mode character varying, warranty_period character varying, delivery_period character varying, contact_person character varying, mobile character varying, po_created_at timestamp without time zone, po_lineitem_count integer, invoice_lineitem_count integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT 
        inv.invoice_id,
        inv.invoice_number,
        inv.invoice_date,
        inv.total_amount,
        inv.po_ref,
        inv.batch_id,
        inv.company_name,
        inv.created_at,

        po.po_id,
        po.po_number,
        po.po_date,
        po.total_amount,
        po.vendor_ref,
        po.delivery_terms,
        po.payment_term,
        po.shipment_mode,
        po.warranty_period,
        po.delivery_period,
        po.contact_person,
        po.mobile,
        po.created_at,

        (SELECT COUNT(*)::INT FROM po_lineitems pli WHERE pli.po_id = po.po_id),
        (SELECT COUNT(*)::INT FROM invoice_lineitems ili WHERE ili.invoice_id = inv.invoice_id)
    FROM invoice_details inv
    JOIN po_details po ON inv.po_ref = po.po_number;
END;
$BODY$;

CREATE OR REPLACE FUNCTION public.get_invoice_with_po_details_by_id(
	invoice_id_input integer)
    RETURNS TABLE(invoice_id integer, invoice_number character varying, invoice_date date, invoice_total numeric, po_ref character varying, batch_id character varying, invoice_created_at timestamp without time zone, po_id integer, po_number character varying, po_date date, po_total numeric, vendor_ref character varying, delivery_terms text, payment_term text, shipment_mode character varying, warranty_period character varying, delivery_period character varying, contact_person character varying, mobile character varying, po_created_at timestamp without time zone, po_lineitem_count integer, invoice_lineitem_count integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY
    SELECT 
        inv.invoice_id,
        inv.invoice_number,
        inv.invoice_date,
        inv.total_amount,
        inv.po_ref,
        inv.batch_id,
        inv.created_at,

        po.po_id,
        po.po_number,
        po.po_date,
        po.total_amount,
        po.vendor_ref,
        po.delivery_terms,
        po.payment_term,
        po.shipment_mode,
        po.warranty_period,
        po.delivery_period,
        po.contact_person,
        po.mobile,
        po.created_at,

        (SELECT COUNT(*)::INT FROM po_lineitems pli WHERE pli.po_id = po.po_id),
        (SELECT COUNT(*)::INT FROM invoice_lineitems ili WHERE ili.invoice_id = inv.invoice_id)

    FROM invoice_details inv
    JOIN po_details po ON inv.po_ref = po.po_number
    WHERE inv.invoice_id = invoice_id_input;
END;
$BODY$;

CREATE OR REPLACE FUNCTION compare_invoice_ewaybill(p_invoice_id INTEGER)
RETURNS TABLE (
    field_name TEXT,
    invoice_value TEXT,
    ewaybill_value TEXT,
    match_status TEXT
)
LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
    SELECT 
        field_name,
        invoice_value,
        ewaybill_value,
        CASE 
            WHEN invoice_value IS NULL AND ewaybill_value IS NULL THEN 'Both NULL'
            WHEN invoice_value = ewaybill_value THEN 'Match'
            ELSE 'Mismatch'
        END AS match_status
    FROM (
        SELECT 
            'Document No'    AS field_name,
            i.invoice_number::TEXT AS invoice_value,
            e.document_no::TEXT AS ewaybill_value
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'Document Date',
            i.invoice_date::TEXT,
            e.document_date::TEXT
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'Value of Goods',
            i.total_amount::TEXT,
            e.value_of_goods::TEXT
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'Vendor Name',
            i.vendor_name,
            e.vendor_name
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'Supplier GSTIN',
            i.supplier_gstin,
            e.gstin_supplier
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'Buyer GSTIN',
            i.buyer_gstin,
            e.gstin_recipient
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'IRN',
            NULL,
            e.irn
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'Client Name',
            NULL,
            e.client_name
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id

        UNION ALL
        SELECT 
            'HSN Code',
            NULL,
            e.hsn_code
        FROM invoice_details i
        JOIN ewaybill_details e 
            ON e.document_no = i.invoice_number
        WHERE i.invoice_id = p_invoice_id
    ) AS comparison;
END;
$$;



CREATE OR REPLACE FUNCTION compare_invoice_ewaybill_by_number(p_invoice_number TEXT)
RETURNS TABLE (
    invoice_number TEXT,
    document_no TEXT,
    invoice_number_match TEXT,
    invoice_date TEXT,
    ewaybill_date TEXT,
    invoice_date_match TEXT,
    supplier_gstin TEXT,
    gstin_supplier TEXT,
    supplier_match TEXT,
    buyer_gstin TEXT,
    gstin_recipient TEXT,
    buyer_match TEXT,
    delivery_location TEXT,
    place_of_delivery TEXT,
    delivery_match TEXT,
    overall_status TEXT
)
LANGUAGE plpgsql
DECLARE
    v_invoice invoice_details%ROWTYPE;
    v_ewaybill ewaybill_details%ROWTYPE;

    match_threshold CONSTANT NUMERIC := 80.0;

    s1 NUMERIC;
    s2 NUMERIC;
    s3 NUMERIC;
    s4 NUMERIC;
    s5 NUMERIC;
BEGIN
    -- Load matching invoice and e-waybill by invoice number
    SELECT * INTO v_invoice 
    FROM invoice_details inv 
    WHERE inv.invoice_number = p_invoice_number;

    SELECT * INTO v_ewaybill 
    FROM ewaybill_details ew 
    WHERE ew.document_no = p_invoice_number;

    -- Compute similarity scores
    s1 := compute_score(v_invoice.invoice_number::TEXT, v_ewaybill.document_no::TEXT);
    s2 := compute_score(v_invoice.invoice_date::TEXT, v_ewaybill.ewaybill_date::TEXT);
    s3 := compute_score(v_invoice.supplier_gstin::TEXT, v_ewaybill.gstin_supplier::TEXT);
    s4 := compute_score(v_invoice.buyer_gstin::TEXT, v_ewaybill.gstin_recipient::TEXT);
    s5 := compute_score(v_invoice.delivery_location::TEXT, v_ewaybill.place_of_delivery::TEXT);

    -- Return row of results
    RETURN QUERY
    SELECT
        v_invoice.invoice_number::TEXT,
        v_ewaybill.document_no::TEXT,
        CASE WHEN s1 >= match_threshold THEN 'yes' ELSE 'no' END AS invoice_number_match,

        v_invoice.invoice_date::TEXT,
        v_ewaybill.ewaybill_date::TEXT,
        CASE WHEN s2 >= match_threshold THEN 'yes' ELSE 'no' END AS invoice_date_match,

        v_invoice.supplier_gstin::TEXT,
        v_ewaybill.gstin_supplier::TEXT,
        CASE WHEN s3 >= match_threshold THEN 'yes' ELSE 'no' END AS supplier_match,

        v_invoice.buyer_gstin::TEXT,
        v_ewaybill.gstin_recipient::TEXT,
        CASE WHEN s4 >= match_threshold THEN 'yes' ELSE 'no' END AS buyer_match,

        v_invoice.delivery_location::TEXT,
        v_ewaybill.place_of_delivery::TEXT,
        CASE WHEN s5 >= match_threshold THEN 'yes' ELSE 'no' END AS delivery_match,

        CASE
            WHEN s1 >= match_threshold 
             AND s2 >= match_threshold 
             AND s3 >= match_threshold 
             AND s4 >= match_threshold 
             AND s5 >= match_threshold
            THEN 'match'
            ELSE 'no match'
        END AS overall_status;
END;
$BODY$;



CREATE OR REPLACE FUNCTION compare_invoice_to_ewaybill()
RETURNS TABLE (
    field_name TEXT,
    status TEXT
)
LANGUAGE plpgsql
AS $BODY$
BEGIN
    RETURN QUERY
    SELECT * FROM (
        VALUES
            ('IRN', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'irn'
            ) THEN 'Missing' ELSE 'Present' END),

            ('GSTIN of Supplier', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'supplier_gstin'
            ) THEN 'Missing' ELSE 'Present' END),

            ('Vendor Name', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'vendor_name'
            ) THEN 'Missing' ELSE 'Present' END),

            ('GSTIN of Recipient', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'buyer_gstin'
            ) THEN 'Missing' ELSE 'Present' END),

            ('Client Name', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'client_name'
            ) THEN 'Missing' ELSE 'Present' END),

            ('Document No', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'invoice_number'
            ) THEN 'Missing' ELSE 'Present' END),

            ('Document Date', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'invoice_date'
            ) THEN 'Missing' ELSE 'Present' END),

            ('Value of Goods', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'total_amount'
            ) THEN 'Missing' ELSE 'Present' END),

            ('HSN Code', CASE WHEN NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'invoice_details' AND column_name = 'hsn_code'
            ) THEN 'Missing' ELSE 'Present' END)
    ) AS result(field_name, status);
END;
$BODY$;

CREATE OR REPLACE FUNCTION compute_score(a TEXT, b TEXT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
    IF a IS NULL OR b IS NULL THEN
        RETURN 0;
    ELSIF a = b THEN
        RETURN 100;
    ELSE
        RETURN GREATEST(
            0,
            100 - (levenshtein(lower(a), lower(b)) * 100.0 / GREATEST(length(a), 1))
        );
    END IF;
END;
$BODY$;


CREATE OR REPLACE FUNCTION generate_invoice_checklist(p_invoice_id INTEGER)
RETURNS TABLE (
    invoice_id INTEGER,
    invoice_number TEXT,
    duplicate_invoice TEXT,
    invoice_date DATE,
    po_date DATE,
    invoice_total NUMERIC(20,2),
    lineitem_total NUMERIC(20,2),
    lineitem_values TEXT,
    invoice_total_check TEXT,
    invoice_vendor_name TEXT,
    master_vendor_name TEXT,
    vendorname_check TEXT,
    supplier_gstin_invoice TEXT,
    supplier_gstin_po TEXT,
    supplier_gstin_check TEXT,
    buyer_gstin_invoice TEXT,
    buyer_gstin_po TEXT,
    buyer_gstin_check TEXT,
    supplier_pan TEXT,
    master_pan TEXT,
    pan_check TEXT,
    gstin_pan_check TEXT,
    gstin_vendor_master TEXT,
    gstin_invoice_master_check TEXT,
    invoice_po_date_check TEXT,
    overall_status TEXT
)
LANGUAGE plpgsql
DECLARE
    v_invoice RECORD;
    v_po RECORD;
    v_vm RECORD;
    v_total_lineitems NUMERIC(20,2) := 0;
    v_values_list TEXT := '';
    v_dup_count INT := 0;
    v_vendor_sim_ratio FLOAT := 0;
    v_vendorname_check TEXT := 'no match';
    v_gstin_invoice_master_check TEXT := 'no match';
    v_invoice_total_check TEXT := 'no match';
    v_supplier_gstin_check TEXT := 'no match';
    v_buyer_gstin_check TEXT := 'no match';
    v_pan_check TEXT := 'no match';
    v_gstin_pan_check TEXT := 'no match';
    v_invoice_po_date_check TEXT := 'no match';
    v_overall_status TEXT := 'match';
BEGIN
    -- Fetch the invoice
    SELECT * INTO v_invoice 
    FROM invoice_details inv 
    WHERE inv.invoice_id = p_invoice_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invoice ID % not found', p_invoice_id;
    END IF;

    -- Count duplicate invoice numbers
    SELECT COUNT(*) INTO v_dup_count
    FROM invoice_details inv
    WHERE inv.invoice_number = v_invoice.invoice_number;

    -- Fetch PO details
    SELECT * INTO v_po 
    FROM po_details po 
    WHERE po.po_number = v_invoice.po_ref;

    -- Fetch vendor master by GSTIN first
    SELECT * INTO v_vm
    FROM vpr_vendor_master vm
    WHERE vm.gstin = v_invoice.supplier_gstin
      AND TRIM(vm.master) <> ''
    LIMIT 1;

    -- Fallback: fuzzy match if vendor not found
    IF v_vm IS NULL THEN
        SELECT * INTO v_vm
        FROM vpr_vendor_master vm
        WHERE TRIM(vm.master) <> ''
        ORDER BY similarity(vm.master, v_invoice.company_name) DESC
        LIMIT 1;
    END IF;

    -- Sum line items
    SELECT
        SUM(li.total_value) AS total_sum,
        STRING_AGG(li.total_value::TEXT, ',') AS values_csv
    INTO
        v_total_lineitems,
        v_values_list
    FROM invoice_lineitems li
    WHERE li.invoice_id = p_invoice_id;

    -- Vendor name similarity
    IF COALESCE(TRIM(v_invoice.company_name), '') <> '' AND COALESCE(TRIM(v_vm.master), '') <> '' THEN
        SELECT similarity(v_invoice.company_name, v_vm.master) INTO v_vendor_sim_ratio;
        v_vendorname_check := ROUND(v_vendor_sim_ratio * 100)::TEXT || '%';
    END IF;

    -- GSTIN invoice vs vendor master
    IF v_invoice.supplier_gstin = v_vm.gstin THEN
        v_gstin_invoice_master_check := 'yes';
    END IF;

    -- Invoice total vs line item total
    IF v_invoice.total_amount IS NOT NULL 
       AND v_total_lineitems IS NOT NULL 
       AND v_invoice.total_amount = v_total_lineitems THEN
        v_invoice_total_check := 'yes';
    END IF;

    -- Supplier GSTIN check with PO
    IF v_invoice.supplier_gstin IS NOT NULL 
       AND v_po.supplier_gstin IS NOT NULL 
       AND v_invoice.supplier_gstin = v_po.supplier_gstin THEN
        v_supplier_gstin_check := 'yes';
    END IF;

    -- Buyer GSTIN check
    IF v_invoice.buyer_gstin IS NOT NULL 
       AND v_po.buyer_gstin IS NOT NULL 
       AND v_invoice.buyer_gstin = v_po.buyer_gstin THEN
        v_buyer_gstin_check := 'yes';
    END IF;

    -- PAN check
    IF v_vm.pan IS NOT NULL THEN
        v_pan_check := 'yes';
    END IF;

    -- GSTIN contains PAN check
    IF v_vm.pan IS NOT NULL 
       AND v_invoice.supplier_gstin IS NOT NULL 
       AND POSITION(v_vm.pan IN v_invoice.supplier_gstin) > 0 THEN
        v_gstin_pan_check := 'yes';
    END IF;

    -- Invoice date <= PO date check
    IF v_invoice.invoice_date IS NOT NULL 
       AND v_po.po_date IS NOT NULL 
       AND v_invoice.invoice_date <= v_po.po_date THEN
        v_invoice_po_date_check := 'yes';
    END IF;

    -- Determine overall status
    IF 'no match' IN (
        v_invoice_total_check,
        v_supplier_gstin_check,
        v_buyer_gstin_check,
        v_pan_check,
        v_gstin_pan_check,
        v_gstin_invoice_master_check,
        v_invoice_po_date_check
    ) THEN
        v_overall_status := 'no match';
    END IF;

    -- Return single structured row
    RETURN QUERY
    SELECT
        v_invoice.invoice_id,
        v_invoice.invoice_number::TEXT,
        CASE WHEN v_dup_count > 1 THEN 'no' ELSE 'yes' END,
        v_invoice.invoice_date,
        v_po.po_date,
        v_invoice.total_amount,
        COALESCE(v_total_lineitems, 0),
        COALESCE(v_values_list, ''),
        v_invoice_total_check,
        v_invoice.vendor_name::TEXT,
        v_vm.master::TEXT,
        COALESCE(v_vendorname_check, 'no match'),
        v_invoice.supplier_gstin::TEXT,
        v_po.supplier_gstin::TEXT,
        v_supplier_gstin_check,
        v_invoice.buyer_gstin::TEXT,
        v_po.buyer_gstin::TEXT,
        v_buyer_gstin_check,
        NULL,  -- supplier_pan placeholder
        v_vm.pan::TEXT,
        v_pan_check,
        v_gstin_pan_check,
        v_vm.gstin::TEXT,
        v_gstin_invoice_master_check,
        v_invoice_po_date_check,
        v_overall_status;
END;
$BODY$;

CREATE OR REPLACE FUNCTION test_get_metadata_checklist(invoice_id_input INTEGER)
RETURNS TABLE (
    field_name TEXT,
    po_present TEXT,
    invoice_present TEXT,
    mrn_present TEXT,
    match_status TEXT,
    notes TEXT
)
LANGUAGE plpgsql
AS $BODY$
BEGIN
  RETURN QUERY
  SELECT
    t.field_name,
    CASE WHEN t.po THEN 'Yes' ELSE 'No' END AS po_present,
    CASE WHEN t.inv THEN 'Yes' ELSE 'No' END AS invoice_present,
    CASE WHEN t.mrn THEN 'Yes' ELSE 'No' END AS mrn_present,

    CASE
      WHEN t.po AND t.inv AND t.mrn THEN 'Match across all'
      WHEN (t.po AND t.inv) OR (t.po AND t.mrn) OR (t.inv AND t.mrn) THEN 'Partial Match'
      ELSE 'Mismatch'
    END AS match_status,

    CASE
      WHEN NOT t.po AND NOT t.inv AND NOT t.mrn THEN 'Missing in all'
      WHEN NOT t.po THEN 'Missing in PO'
      WHEN NOT t.inv THEN 'Missing in Invoice'
      WHEN NOT t.mrn THEN 'Missing in MRN'
      ELSE 'Present in all'
    END AS notes

  FROM (
    VALUES
      -- Vendor Name
      ('Vendor Name',
        EXISTS (
          SELECT 1 FROM po_details
          WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND vendor_name IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM invoice_details
          WHERE invoice_id = invoice_id_input AND vendor_name IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM mrn_details
          WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND vendor_name IS NOT NULL
        )
      ),

      -- Supplier GSTIN
      ('Supplier GSTIN',
        EXISTS (
          SELECT 1 FROM po_details
          WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND supplier_gstin IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM invoice_details
          WHERE invoice_id = invoice_id_input AND supplier_gstin IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM mrn_details
          WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND supplier_gstin IS NOT NULL
        )
      ),

      -- Buyer GSTIN
      ('Buyer GSTIN',
        EXISTS (
          SELECT 1 FROM po_details
          WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND buyer_gstin IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM invoice_details
          WHERE invoice_id = invoice_id_input AND buyer_gstin IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM mrn_details
          WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND buyer_gstin IS NOT NULL
        )
      ),

      -- Delivery Location
      ('Delivery Location',
        EXISTS (
          SELECT 1 FROM po_details
          WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND delivery_location IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM invoice_details
          WHERE invoice_id = invoice_id_input AND delivery_location IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM mrn_details
          WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND delivery_location IS NOT NULL
        )
      ),

      -- Invoice Total
      ('Invoice Total',
        EXISTS (
          SELECT 1 FROM po_details
          WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND total_amount IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM invoice_details
          WHERE invoice_id = invoice_id_input AND total_amount IS NOT NULL
        ),
        EXISTS (
          SELECT 1 FROM mrn_details
          WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input)
          AND total_amount IS NOT NULL
        )
      )
  ) AS t(field_name, po, inv, mrn);
END;
$BODY$;
    """

    try:
        with psycopg2.connect(**db_url) as conn:
            conn.set_session(autocommit=True)
            with conn.cursor() as cur:
                print(f"🚀 Creating RAO tables in '{db_name}'...")
                cur.execute(schema_sql)
                print("✅ Tables created successfully.")
    except Exception as e:
        print(f"❌ Error:", e)