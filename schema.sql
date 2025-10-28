CREATE TABLE IF NOT EXISTS public.hypotus_bbox
(
    id integer NOT NULL DEFAULT nextval('hypotus_bbox_id_seq'::regclass),
    image_path character varying(255) COLLATE pg_catalog."default",
    bbox text COLLATE pg_catalog."default",
    CONSTRAINT hypotus_bbox_pkey PRIMARY KEY (id)
)


	
CREATE TABLE IF NOT EXISTS public.image_classification_hypotus
(
    claim_id character varying(255) COLLATE pg_catalog."default" NOT NULL,
    image character varying(255) COLLATE pg_catalog."default" NOT NULL,
    blob_image text COLLATE pg_catalog."default" NOT NULL,
    top_label character varying(100) COLLATE pg_catalog."default" NOT NULL,
    confidence numeric(5,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    batchid bigint,
    id integer NOT NULL DEFAULT nextval('image_classification_hypotus_id_seq'::regclass),
    mapping_id character varying COLLATE pg_catalog."default",
    CONSTRAINT image_classification_hypotus_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.image_classification_hypotus
    OWNER to postgres;
	
CREATE TABLE IF NOT EXISTS public.image_duplicates
(
    id integer NOT NULL DEFAULT nextval('image_duplicates_id_seq'::regclass),
    reference_image text COLLATE pg_catalog."default",
    target_image text COLLATE pg_catalog."default",
    feature_similarity numeric,
    text_similarity numeric,
    reference_tampering_score numeric,
    target_tampering_score numeric,
    duplicate_status text COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    pdf_ref_id character varying COLLATE pg_catalog."default",
    CONSTRAINT image_duplicates_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.image_duplicates
    OWNER to postgres;
	
	CREATE TABLE IF NOT EXISTS public.invoice_asset_details
(
    id integer NOT NULL DEFAULT nextval('invoice_asset_details_id_seq'::regclass),
    invoice_id integer,
    material_code character varying(100) COLLATE pg_catalog."default",
    chassis_number character varying(100) COLLATE pg_catalog."default",
    engine_number character varying(100) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_asset_details_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_asset_details
    OWNER to postgres;
	
CREATE TABLE IF NOT EXISTS public.invoice_bank_details
(
    id integer NOT NULL DEFAULT nextval('invoice_bank_details_id_seq'::regclass),
    invoice_id integer,
    account_holder_name character varying(255) COLLATE pg_catalog."default",
    bank_name character varying(255) COLLATE pg_catalog."default",
    account_number character varying(100) COLLATE pg_catalog."default",
    ifsc_code character varying(20) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    branch_name character varying COLLATE pg_catalog."default",
    CONSTRAINT invoice_bank_details_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_bank_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.invoice_buyer_details
(
    id integer NOT NULL DEFAULT nextval('invoice_buyer_details_id_seq'::regclass),
    invoice_id integer,
    buyer_company_name character varying(255) COLLATE pg_catalog."default",
    buyer_address text COLLATE pg_catalog."default",
    buyer_state character varying(100) COLLATE pg_catalog."default",
    buyer_state_code character varying(10) COLLATE pg_catalog."default",
    buyer_gstin character varying(100) COLLATE pg_catalog."default",
    buyer_pan character varying(20) COLLATE pg_catalog."default",
    buyer_cin character varying(50) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_buyer_details_pkey PRIMARY KEY (id),
    CONSTRAINT invoice_buyer_details_invoice_id_fkey FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_buyer_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.invoice_check_list
(
    id integer NOT NULL DEFAULT nextval('invoice_check_list_id_seq'::regclass),
    pdf_ref_id integer,
    invoice_number text COLLATE pg_catalog."default",
    invoice_date text COLLATE pg_catalog."default",
    vendor_name text COLLATE pg_catalog."default",
    address text COLLATE pg_catalog."default",
    supplier_gstin text COLLATE pg_catalog."default",
    buyer_gstin text COLLATE pg_catalog."default",
    supplier_pan text COLLATE pg_catalog."default",
    gstin_pan text COLLATE pg_catalog."default",
    invoice_sum_amount_total_amount numeric(15,2),
    is_duplicate boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_check_list_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_check_list
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.invoice_details
(
    invoice_id integer NOT NULL DEFAULT nextval('invoice_details_invoice_id_seq'::regclass),
    invoice_number character varying(100) COLLATE pg_catalog."default",
    invoice_date date,
    total_amount numeric(20,2),
    po_ref character varying(100) COLLATE pg_catalog."default",
    batch_id character varying(100) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    company_name character varying COLLATE pg_catalog."default",
    vendor_name character varying(255) COLLATE pg_catalog."default",
    supplier_gstin character varying(15) COLLATE pg_catalog."default",
    buyer_gstin character varying(15) COLLATE pg_catalog."default",
    delivery_location character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT invoice_details_pkey PRIMARY KEY (invoice_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.invoice_lineitems
(
    item_id integer NOT NULL DEFAULT nextval('invoice_lineitems_item_id_seq'::regclass),
    item_name character varying(255) COLLATE pg_catalog."default",
    hsn character varying(50) COLLATE pg_catalog."default",
    quantity numeric(15,2),
    uom character varying(50) COLLATE pg_catalog."default",
    rate_incl_of_tax numeric(15,2),
    unit_price numeric(15,2),
    total_retail_price numeric(15,2),
    total_taxable_amount numeric(15,2),
    total_value numeric(20,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    invoice_id integer,
    discount character varying COLLATE pg_catalog."default" DEFAULT 0,
    CONSTRAINT invoice_lineitems_pkey PRIMARY KEY (item_id),
    CONSTRAINT invoice_id FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_lineitems
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.invoice_shipping_details
(
    id integer NOT NULL DEFAULT nextval('invoice_shipping_details_id_seq'::regclass),
    invoice_id integer,
    ship_to_company_name character varying(255) COLLATE pg_catalog."default",
    ship_to_address text COLLATE pg_catalog."default",
    ship_to_state character varying(100) COLLATE pg_catalog."default",
    ship_to_state_code character varying(50) COLLATE pg_catalog."default",
    ship_to_gstin character varying(50) COLLATE pg_catalog."default",
    ship_to_pan character varying(50) COLLATE pg_catalog."default",
    ship_to_cin character varying(50) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_shipping_details_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_shipping_details
    OWNER to postgres;


    -------------------------------
	

CREATE TABLE IF NOT EXISTS public.invoice_summary
(
    id integer NOT NULL DEFAULT nextval('invoice_summary_id_seq'::regclass),
    invoice_id integer,
    total_discount_value numeric(15,2),
    total_quantity numeric(15,2),
    total_taxable_amount numeric(15,2),
    tcs_rate character varying(10) COLLATE pg_catalog."default",
    taxable_value numeric(15,2),
    total_cgst_amount numeric(15,2),
    total_sgst_amount numeric(15,2),
    total_tax_amount numeric(15,2),
    total_invoice_value numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT invoice_summary_pkey PRIMARY KEY (id),
    CONSTRAINT invoice_summary_invoice_id_fkey FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_summary
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.invoice_supplier_details
(
    id integer NOT NULL DEFAULT nextval('invoice_supplier_details_id_seq'::regclass),
    invoice_id integer,
    pan_supplier character varying(20) COLLATE pg_catalog."default",
    gstin_supplier character varying(50) COLLATE pg_catalog."default",
    udyam_regno character varying(100) COLLATE pg_catalog."default",
    state character varying(100) COLLATE pg_catalog."default",
    state_code character varying(10) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    supplier_name character varying(255) COLLATE pg_catalog."default",
    supplier_address text COLLATE pg_catalog."default",
    CONSTRAINT invoice_supplier_details_pkey PRIMARY KEY (id),
    CONSTRAINT invoice_supplier_details_invoice_id_fkey FOREIGN KEY (invoice_id)
        REFERENCES public.invoice_details (invoice_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.invoice_supplier_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.mrn_buyer_details
(
    id integer NOT NULL DEFAULT nextval('mrn_buyer_details_id_seq'::regclass),
    mrn_id integer,
    received_at text COLLATE pg_catalog."default",
    received_address text COLLATE pg_catalog."default",
    gstin_receiving_party character varying(50) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mrn_buyer_details_pkey PRIMARY KEY (id),
    CONSTRAINT mrn_buyer_details_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mrn_buyer_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.mrn_details
(
    id integer NOT NULL DEFAULT nextval('mrn_details_id_seq'::regclass),
    mrn_number character varying(100) COLLATE pg_catalog."default",
    mrn_date date,
    po_reference_number character varying(100) COLLATE pg_catalog."default",
    po_date date,
    ref_invoice_number character varying(100) COLLATE pg_catalog."default",
    ref_invoice_date date,
    info text COLLATE pg_catalog."default",
    remarks text COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    vendor_name character varying(255) COLLATE pg_catalog."default",
    supplier_gstin character varying(15) COLLATE pg_catalog."default",
    buyer_gstin character varying(15) COLLATE pg_catalog."default",
    delivery_location character varying(255) COLLATE pg_catalog."default",
    total_amount character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT mrn_details_pkey PRIMARY KEY (id),
    CONSTRAINT mrn_details_mrn_number_key UNIQUE (mrn_number)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mrn_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.mrn_lineitems
(
    item_id integer NOT NULL DEFAULT nextval('mrn_lineitems_item_id_seq'::regclass),
    mrn_id integer,
    item_name text COLLATE pg_catalog."default",
    received_quantity numeric(10,2),
    hsn_sac character varying(50) COLLATE pg_catalog."default",
    uom character varying(20) COLLATE pg_catalog."default",
    mrp numeric(15,2),
    unit_price numeric(15,2),
    discount numeric(15,2),
    gross_amount numeric(15,2),
    net_amount numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    gst_rate character varying COLLATE pg_catalog."default",
    CONSTRAINT mrn_lineitems_pkey PRIMARY KEY (item_id),
    CONSTRAINT mrn_lineitems_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mrn_lineitems
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.mrn_summary
(
    id integer NOT NULL DEFAULT nextval('mrn_summary_id_seq'::regclass),
    mrn_id integer,
    cgst numeric(15,2),
    sgst numeric(15,2),
    igst numeric(15,2),
    gst_amount numeric(15,2),
    cess numeric(15,2),
    total_qty numeric(10,2),
    total_value numeric(20,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mrn_summary_pkey PRIMARY KEY (id),
    CONSTRAINT mrn_summary_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mrn_summary
    OWNER to postgres;


    ++++++++++++++++++++++++++++++++++++++++++++++++++____________________________________________

CREATE TABLE IF NOT EXISTS public.mrn_supplier_details
(
    id integer NOT NULL DEFAULT nextval('mrn_supplier_details_id_seq'::regclass),
    mrn_id integer,
    supplier_name text COLLATE pg_catalog."default",
    supplier_address text COLLATE pg_catalog."default",
    gstin_supplier character varying(20) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mrn_supplier_details_pkey PRIMARY KEY (id),
    CONSTRAINT mrn_supplier_details_mrn_id_fkey FOREIGN KEY (mrn_id)
        REFERENCES public.mrn_details (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mrn_supplier_details
    OWNER to postgres;
	
	
CREATE TABLE IF NOT EXISTS public.pdf_conversion_hypotus
(
    id integer NOT NULL DEFAULT nextval('pdf_conversion_hypotus_id_seq'::regclass),
    claim_id character varying(255) COLLATE pg_catalog."default" NOT NULL,
    num_pdfs integer NOT NULL,
    num_images integer NOT NULL,
    status character varying(50) COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    batchid bigint,
    CONSTRAINT pdf_conversion_hypotus_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.pdf_conversion_hypotus
    OWNER to postgres;

CREATE TABLE IF NOT EXISTS public.po_billto
(
    id integer NOT NULL DEFAULT nextval('po_billto_id_seq'::regclass),
    po_id integer,
    bill_to character varying(255) COLLATE pg_catalog."default",
    billing_address text COLLATE pg_catalog."default",
    gstin_buyer character varying(50) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_billto_pkey PRIMARY KEY (id),
    CONSTRAINT po_billto_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.po_billto
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.po_details
(
    po_id integer NOT NULL DEFAULT nextval('po_details_po_id_seq'::regclass),
    po_number character varying(100) COLLATE pg_catalog."default",
    po_date date,
    total_amount numeric(15,2),
    vendor_ref character varying(255) COLLATE pg_catalog."default",
    delivery_terms text COLLATE pg_catalog."default",
    payment_term text COLLATE pg_catalog."default",
    shipment_mode character varying(100) COLLATE pg_catalog."default",
    warranty_period character varying(100) COLLATE pg_catalog."default",
    delivery_period character varying(100) COLLATE pg_catalog."default",
    contact_person character varying(100) COLLATE pg_catalog."default",
    mobile character varying(20) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    item_code character varying COLLATE pg_catalog."default",
    vendor_name character varying(255) COLLATE pg_catalog."default",
    supplier_gstin character varying(15) COLLATE pg_catalog."default",
    buyer_gstin character varying(15) COLLATE pg_catalog."default",
    delivery_location character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT po_details_pkey PRIMARY KEY (po_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.po_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.po_lineitems
(
    item_id integer NOT NULL DEFAULT nextval('po_line_items_item_id_seq'::regclass),
    po_id integer NOT NULL,
    item_name character varying(255) COLLATE pg_catalog."default",
    oem_part_code character varying(100) COLLATE pg_catalog."default",
    quantity numeric(15,2),
    uom character varying(50) COLLATE pg_catalog."default",
    unit_price numeric(15,2),
    discount numeric(15,2),
    taxable numeric(15,2),
    gst_rate numeric(5,2),
    gst_amount numeric(15,2),
    billable_value numeric(15,2),
    total_qty numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_line_items_pkey PRIMARY KEY (item_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.po_lineitems
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.po_shipping_details
(
    id integer NOT NULL DEFAULT nextval('po_shipping_details_id_seq'::regclass),
    po_id integer,
    ship_to character varying(255) COLLATE pg_catalog."default",
    shipping_address text COLLATE pg_catalog."default",
    gstin_buyer character varying(50) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_shipping_details_pkey PRIMARY KEY (id),
    CONSTRAINT po_shipping_details_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.po_shipping_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.po_summary
(
    id integer NOT NULL DEFAULT nextval('po_summary_id_seq'::regclass),
    po_id integer NOT NULL,
    total_qty numeric(15,2),
    total_rate numeric(15,2),
    total_discount numeric(15,2),
    total_taxable_amount numeric(15,2),
    total_gst_amt numeric(15,2),
    total_billable_value numeric(15,2),
    charges_and_deductions numeric(15,2),
    total_purchase_order_amount numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_summary_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.po_summary
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.po_supplier_details
(
    id integer NOT NULL DEFAULT nextval('po_supplier_details_id_seq'::regclass),
    po_id integer,
    supplier_name character varying(255) COLLATE pg_catalog."default",
    supplier_code character varying(255) COLLATE pg_catalog."default",
    gstin_supplier character varying(50) COLLATE pg_catalog."default",
    supplier_address text COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_supplier_details_pkey PRIMARY KEY (id),
    CONSTRAINT po_supplier_details_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.po_supplier_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.po_terms_conditions
(
    id integer NOT NULL DEFAULT nextval('po_terms_conditions_id_seq'::regclass),
    po_id integer,
    terms_conditions text COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT po_terms_conditions_pkey PRIMARY KEY (id),
    CONSTRAINT po_terms_conditions_po_id_fkey FOREIGN KEY (po_id)
        REFERENCES public.po_details (po_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.po_terms_conditions
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.purchase_order_details
(
    id integer NOT NULL DEFAULT nextval('purchase_order_details_id_seq'::regclass),
    batch_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
    po_no character varying(100) COLLATE pg_catalog."default" NOT NULL,
    po_date date,
    vendor_ref character varying(150) COLLATE pg_catalog."default",
    delivery_terms character varying(255) COLLATE pg_catalog."default",
    payment_terms character varying(255) COLLATE pg_catalog."default",
    shipment_mode character varying(150) COLLATE pg_catalog."default",
    warranty_period character varying(150) COLLATE pg_catalog."default",
    delivery_period character varying(150) COLLATE pg_catalog."default",
    contact_person character varying(150) COLLATE pg_catalog."default",
    mobile_number character varying(50) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT purchase_order_details_pkey PRIMARY KEY (id),
    CONSTRAINT purchase_order_details_po_no_key UNIQUE (po_no)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.purchase_order_details
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.rao_details
(
    rao_id integer NOT NULL DEFAULT nextval('rao_details_rao_id_seq'::regclass),
    rao_number character varying(100) COLLATE pg_catalog."default",
    rao_date date,
    po_reference_number character varying(100) COLLATE pg_catalog."default",
    po_date date,
    ref_invoice_number character varying(100) COLLATE pg_catalog."default",
    ref_invoice_date date,
    document_title text COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rao_details_pkey PRIMARY KEY (rao_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.rao_details
    OWNER to postgres;



    +++++++++++++++++++++++++++++++++++++
	

CREATE TABLE IF NOT EXISTS public.rao_lineitems
(
    item_id integer NOT NULL DEFAULT nextval('rao_lineitems_item_id_seq'::regclass),
    rao_id integer,
    item_name text COLLATE pg_catalog."default",
    received_quantity numeric(10,2),
    hsn_sac character varying(50) COLLATE pg_catalog."default",
    unit_price numeric(15,2),
    discount numeric(15,2),
    gst_rate numeric(5,2),
    total_value numeric(20,2),
    engine_no character varying(100) COLLATE pg_catalog."default",
    chasis_no character varying(100) COLLATE pg_catalog."default",
    serial_no character varying(100) COLLATE pg_catalog."default",
    asset_id character varying(100) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rao_lineitems_pkey PRIMARY KEY (item_id),
    CONSTRAINT rao_lineitems_rao_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.rao_lineitems
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.rao_receivedat
(
    id integer NOT NULL DEFAULT nextval('rao_receivedat_id_seq'::regclass),
    rao_id integer,
    received_date date,
    received_at text COLLATE pg_catalog."default",
    received_address text COLLATE pg_catalog."default",
    gstin_receiving_party character varying(100) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rao_receivedat_pkey PRIMARY KEY (id),
    CONSTRAINT rao_receivedat_grn_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.rao_receivedat
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.rao_summary
(
    id integer NOT NULL DEFAULT nextval('rao_summary_id_seq'::regclass),
    rao_id integer,
    total_discount numeric(15,2),
    cgst numeric(15,2),
    sgst numeric(15,2),
    igst numeric(15,2),
    gst_amount numeric(15,2),
    cess numeric(15,2),
    total_qty numeric(15,2),
    total_value numeric(20,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    gross_amount character varying COLLATE pg_catalog."default",
    sub_total character varying COLLATE pg_catalog."default",
    CONSTRAINT rao_summary_pkey PRIMARY KEY (id),
    CONSTRAINT rao_summary_rao_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.rao_summary
    OWNER to postgres;
	

CREATE TABLE IF NOT EXISTS public.rao_supplier_details
(
    id integer NOT NULL DEFAULT nextval('rao_supplier_details_id_seq'::regclass),
    rao_id integer,
    supplier_name text COLLATE pg_catalog."default",
    supplier_address text COLLATE pg_catalog."default",
    gstin_supplier character varying(50) COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT rao_supplier_details_pkey PRIMARY KEY (id),
    CONSTRAINT rao_supplier_details_rao_id_fkey FOREIGN KEY (rao_id)
        REFERENCES public.rao_details (rao_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.rao_supplier_details
    OWNER to postgres;