--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2025-08-05 14:23:26

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 16386)
-- Name: pu2pay_v1; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pu2pay_v1;


ALTER SCHEMA pu2pay_v1 OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 16387)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 5234 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 333 (class 1255 OID 24579)
-- Name: get_3_way_checklist(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_3_way_checklist(invoice_id_input integer) RETURNS TABLE(field_name text, po_present text, invoice_present text, mrn_present text, match_status text, notes text)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_3_way_checklist(invoice_id_input integer) OWNER TO postgres;

--
-- TOC entry 326 (class 1255 OID 16469)
-- Name: get_3way_match_results(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_3way_match_results(invoice_id_input integer) RETURNS TABLE(item_name text, po_qty numeric, invoice_qty numeric, mrn_qty numeric, po_invoice_match_percent numeric, invoice_mrn_match_percent numeric, match_status text)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_3way_match_results(invoice_id_input integer) OWNER TO postgres;

--
-- TOC entry 327 (class 1255 OID 16470)
-- Name: get_combined_transaction_summary(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_combined_transaction_summary(invoice_id_input integer) RETURNS TABLE(po_number character varying, invoice_id integer, invoice_number character varying, mrn_number character varying, po_total_qty numeric, po_total_rate numeric, po_total_discount numeric, po_taxable numeric, po_total_gst numeric, po_total_billable numeric, po_total_value numeric, invoice_total_discount numeric, invoice_total_qty numeric, invoice_taxable numeric, invoice_cgst numeric, invoice_sgst numeric, invoice_total_tax numeric, invoice_total_value numeric, mrn_total_qty numeric, mrn_cgst numeric, mrn_sgst numeric, mrn_igst numeric, mrn_total_gst numeric, mrn_total_value numeric)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_combined_transaction_summary(invoice_id_input integer) OWNER TO postgres;

--
-- TOC entry 328 (class 1255 OID 16471)
-- Name: get_invoice_po_match_results(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_invoice_po_match_results(invoice_id_input integer) RETURNS TABLE(inv_id integer, po_id integer, invoice_item text, po_item text, item_name_match_percent numeric, invoice_qty numeric, po_qty numeric, quantity_match_percent numeric, total_taxable_amount numeric, po_unit_price numeric, unit_price_match_percent numeric, invoice_total_value numeric, po_total_value numeric, total_value_match_percent numeric, match_status text, mismatch_reason text)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_invoice_po_match_results(invoice_id_input integer) OWNER TO postgres;

--
-- TOC entry 329 (class 1255 OID 16472)
-- Name: get_invoice_po_match_results_v2(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_invoice_po_match_results_v2(invoice_id_input integer) RETURNS TABLE(inv_id integer, po_id integer, invoice_item text, po_item text, item_name_match_percent numeric, invoice_qty numeric, po_qty numeric, quantity_match_percent numeric, total_taxable_amount numeric, po_unit_price numeric, unit_price_match_percent numeric, invoice_total_value numeric, po_total_value numeric, total_value_match_percent numeric, match_status text, mismatch_reason text)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_invoice_po_match_results_v2(invoice_id_input integer) OWNER TO postgres;

--
-- TOC entry 330 (class 1255 OID 16473)
-- Name: get_invoice_po_summary(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_invoice_po_summary(invoice_id_input integer) RETURNS TABLE(invoice_number text, po_ref text, po_number text, invoice_amount numeric, po_amount numeric, amount_match_percentage numeric, po_number_match text)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_invoice_po_summary(invoice_id_input integer) OWNER TO postgres;

--
-- TOC entry 331 (class 1255 OID 16474)
-- Name: get_invoice_with_po_details(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_invoice_with_po_details() RETURNS TABLE(invoice_id integer, invoice_number character varying, invoice_date date, invoice_total numeric, po_ref character varying, batch_id character varying, company_name character varying, invoice_created_at timestamp without time zone, po_id integer, po_number character varying, po_date date, po_total numeric, vendor_ref character varying, delivery_terms text, payment_term text, shipment_mode character varying, warranty_period character varying, delivery_period character varying, contact_person character varying, mobile character varying, po_created_at timestamp without time zone, po_lineitem_count integer, invoice_lineitem_count integer)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_invoice_with_po_details() OWNER TO postgres;

--
-- TOC entry 332 (class 1255 OID 16475)
-- Name: get_invoice_with_po_details_by_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_invoice_with_po_details_by_id(invoice_id_input integer) RETURNS TABLE(invoice_id integer, invoice_number character varying, invoice_date date, invoice_total numeric, po_ref character varying, batch_id character varying, invoice_created_at timestamp without time zone, po_id integer, po_number character varying, po_date date, po_total numeric, vendor_ref character varying, delivery_terms text, payment_term text, shipment_mode character varying, warranty_period character varying, delivery_period character varying, contact_person character varying, mobile character varying, po_created_at timestamp without time zone, po_lineitem_count integer, invoice_lineitem_count integer)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_invoice_with_po_details_by_id(invoice_id_input integer) OWNER TO postgres;

--
-- TOC entry 314 (class 1255 OID 16476)
-- Name: get_metadata_checklist(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_metadata_checklist(invoice_id_input integer) RETURNS TABLE(field_name text, po_present text, invoice_present text, mrn_present text, match_status text, notes text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.field_name,
    CASE WHEN t.po THEN 'Yes' ELSE 'No' END AS po_present,
    CASE WHEN t.inv THEN 'Yes' ELSE 'No' END AS invoice_present,
    CASE WHEN t.mrn THEN 'Yes' ELSE 'No' END AS mrn_present,
    CASE 
      WHEN t.po AND t.inv AND t.mrn THEN '✔️'
      WHEN t.po AND t.inv THEN '⚠️'
      WHEN t.po AND t.mrn THEN '⚠️'
      WHEN t.inv AND t.mrn THEN '⚠️'
      ELSE '❌'
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
      ('Vendor Name', 
        EXISTS (SELECT 1 FROM po_details WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND vendor_name IS NOT NULL),
        EXISTS (SELECT 1 FROM invoice_details WHERE invoice_id = invoice_id_input AND vendor_name IS NOT NULL),
        EXISTS (SELECT 1 FROM mrn_details WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND vendor_name IS NOT NULL)
      ),
      ('Supplier GSTIN', 
        EXISTS (SELECT 1 FROM po_details WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND supplier_gstin IS NOT NULL),
        EXISTS (SELECT 1 FROM invoice_details WHERE invoice_id = invoice_id_input AND supplier_gstin IS NOT NULL),
        EXISTS (SELECT 1 FROM mrn_details WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND supplier_gstin IS NOT NULL)
      ),
      ('Buyer GSTIN', 
        EXISTS (SELECT 1 FROM po_details WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND buyer_gstin IS NOT NULL),
        EXISTS (SELECT 1 FROM invoice_details WHERE invoice_id = invoice_id_input AND buyer_gstin IS NOT NULL),
        EXISTS (SELECT 1 FROM mrn_details WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND buyer_gstin IS NOT NULL)
      ),
      ('Delivery Location', 
        EXISTS (SELECT 1 FROM po_details WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND delivery_location IS NOT NULL),
        EXISTS (SELECT 1 FROM invoice_details WHERE invoice_id = invoice_id_input AND delivery_location IS NOT NULL),
        EXISTS (SELECT 1 FROM mrn_details WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND delivery_location IS NOT NULL)
      ),
      ('Invoice Total', 
        EXISTS (SELECT 1 FROM po_details WHERE po_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND total_amount IS NOT NULL),
        EXISTS (SELECT 1 FROM invoice_details WHERE invoice_id = invoice_id_input AND total_amount IS NOT NULL),
        EXISTS (SELECT 1 FROM mrn_details WHERE po_reference_number = (SELECT po_ref FROM invoice_details WHERE invoice_id = invoice_id_input) AND total_amount IS NOT NULL)
      )
  ) AS t(field_name, po, inv, mrn);
END;
$$;


ALTER FUNCTION public.get_metadata_checklist(invoice_id_input integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 16477)
-- Name: hypotus_bbox; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hypotus_bbox (
    id integer NOT NULL,
    image_path character varying(255),
    bbox text
);


ALTER TABLE public.hypotus_bbox OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16482)
-- Name: hypotus_bbox_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hypotus_bbox_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hypotus_bbox_id_seq OWNER TO postgres;

--
-- TOC entry 5235 (class 0 OID 0)
-- Dependencies: 220
-- Name: hypotus_bbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hypotus_bbox_id_seq OWNED BY public.hypotus_bbox.id;


--
-- TOC entry 221 (class 1259 OID 16483)
-- Name: image_classification_hypotus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.image_classification_hypotus (
    claim_id character varying(255) NOT NULL,
    image character varying(255) NOT NULL,
    blob_image text NOT NULL,
    top_label character varying(100) NOT NULL,
    confidence numeric(5,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    batchid bigint,
    id integer NOT NULL,
    mapping_id character varying
);


ALTER TABLE public.image_classification_hypotus OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16489)
-- Name: image_classification_hypotus_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.image_classification_hypotus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.image_classification_hypotus_id_seq OWNER TO postgres;

--
-- TOC entry 5236 (class 0 OID 0)
-- Dependencies: 222
-- Name: image_classification_hypotus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.image_classification_hypotus_id_seq OWNED BY public.image_classification_hypotus.id;


--
-- TOC entry 223 (class 1259 OID 16490)
-- Name: image_duplicates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.image_duplicates (
    id integer NOT NULL,
    reference_image text,
    target_image text,
    feature_similarity numeric,
    text_similarity numeric,
    reference_tampering_score numeric,
    target_tampering_score numeric,
    duplicate_status text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    pdf_ref_id character varying
);


ALTER TABLE public.image_duplicates OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16496)
-- Name: image_duplicates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.image_duplicates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.image_duplicates_id_seq OWNER TO postgres;

--
-- TOC entry 5237 (class 0 OID 0)
-- Dependencies: 224
-- Name: image_duplicates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.image_duplicates_id_seq OWNED BY public.image_duplicates.id;


--
-- TOC entry 225 (class 1259 OID 16497)
-- Name: invoice_asset_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_asset_details (
    id integer NOT NULL,
    invoice_id integer,
    material_code character varying(100),
    chassis_number character varying(100),
    engine_number character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.invoice_asset_details OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16502)
-- Name: invoice_asset_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_asset_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_asset_details_id_seq OWNER TO postgres;

--
-- TOC entry 5238 (class 0 OID 0)
-- Dependencies: 226
-- Name: invoice_asset_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_asset_details_id_seq OWNED BY public.invoice_asset_details.id;


--
-- TOC entry 227 (class 1259 OID 16503)
-- Name: invoice_bank_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_bank_details (
    id integer NOT NULL,
    invoice_id integer,
    account_holder_name character varying(255),
    bank_name character varying(255),
    account_number character varying(100),
    ifsc_code character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    branch_name character varying
);


ALTER TABLE public.invoice_bank_details OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16510)
-- Name: invoice_bank_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_bank_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_bank_details_id_seq OWNER TO postgres;

--
-- TOC entry 5239 (class 0 OID 0)
-- Dependencies: 228
-- Name: invoice_bank_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_bank_details_id_seq OWNED BY public.invoice_bank_details.id;


--
-- TOC entry 229 (class 1259 OID 16511)
-- Name: invoice_buyer_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_buyer_details (
    id integer NOT NULL,
    invoice_id integer,
    buyer_company_name character varying(255),
    buyer_address text,
    buyer_state character varying(100),
    buyer_state_code character varying(10),
    buyer_gstin character varying(100),
    buyer_pan character varying(20),
    buyer_cin character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.invoice_buyer_details OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16518)
-- Name: invoice_buyer_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_buyer_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_buyer_details_id_seq OWNER TO postgres;

--
-- TOC entry 5240 (class 0 OID 0)
-- Dependencies: 230
-- Name: invoice_buyer_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_buyer_details_id_seq OWNED BY public.invoice_buyer_details.id;


--
-- TOC entry 231 (class 1259 OID 16519)
-- Name: invoice_check_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_check_list (
    id integer NOT NULL,
    pdf_ref_id integer,
    invoice_number text,
    invoice_date text,
    vendor_name text,
    address text,
    supplier_gstin text,
    buyer_gstin text,
    supplier_pan text,
    gstin_pan text,
    invoice_sum_amount_total_amount numeric(15,2),
    is_duplicate boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.invoice_check_list OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16526)
-- Name: invoice_check_list_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_check_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_check_list_id_seq OWNER TO postgres;

--
-- TOC entry 5241 (class 0 OID 0)
-- Dependencies: 232
-- Name: invoice_check_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_check_list_id_seq OWNED BY public.invoice_check_list.id;


--
-- TOC entry 233 (class 1259 OID 16527)
-- Name: invoice_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_details (
    invoice_id integer NOT NULL,
    invoice_number character varying(100),
    invoice_date date,
    total_amount numeric(20,2),
    po_ref character varying(100),
    batch_id character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    company_name character varying,
    vendor_name character varying(255),
    supplier_gstin character varying(15),
    buyer_gstin character varying(15),
    delivery_location character varying(255)
);


ALTER TABLE public.invoice_details OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16534)
-- Name: invoice_details_invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_details_invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_details_invoice_id_seq OWNER TO postgres;

--
-- TOC entry 5242 (class 0 OID 0)
-- Dependencies: 234
-- Name: invoice_details_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_details_invoice_id_seq OWNED BY public.invoice_details.invoice_id;


--
-- TOC entry 235 (class 1259 OID 16535)
-- Name: invoice_lineitems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_lineitems (
    item_id integer NOT NULL,
    item_name character varying(255),
    hsn character varying(50),
    quantity numeric(15,2),
    uom character varying(50),
    rate_incl_of_tax numeric(15,2),
    unit_price numeric(15,2),
    total_retail_price numeric(15,2),
    total_taxable_amount numeric(15,2),
    total_value numeric(20,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    invoice_id integer,
    discount character varying DEFAULT 0
);


ALTER TABLE public.invoice_lineitems OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16543)
-- Name: invoice_lineitems_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_lineitems_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_lineitems_item_id_seq OWNER TO postgres;

--
-- TOC entry 5243 (class 0 OID 0)
-- Dependencies: 236
-- Name: invoice_lineitems_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_lineitems_item_id_seq OWNED BY public.invoice_lineitems.item_id;


--
-- TOC entry 237 (class 1259 OID 16544)
-- Name: invoice_shipping_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_shipping_details (
    id integer NOT NULL,
    invoice_id integer,
    ship_to_company_name character varying(255),
    ship_to_address text,
    ship_to_state character varying(100),
    ship_to_state_code character varying(50),
    ship_to_gstin character varying(50),
    ship_to_pan character varying(50),
    ship_to_cin character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.invoice_shipping_details OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16551)
-- Name: invoice_shipping_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_shipping_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_shipping_details_id_seq OWNER TO postgres;

--
-- TOC entry 5244 (class 0 OID 0)
-- Dependencies: 238
-- Name: invoice_shipping_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_shipping_details_id_seq OWNED BY public.invoice_shipping_details.id;


--
-- TOC entry 239 (class 1259 OID 16552)
-- Name: invoice_summary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_summary (
    id integer NOT NULL,
    invoice_id integer,
    total_discount_value numeric(15,2),
    total_quantity numeric(15,2),
    total_taxable_amount numeric(15,2),
    tcs_rate character varying(10),
    taxable_value numeric(15,2),
    total_cgst_amount numeric(15,2),
    total_sgst_amount numeric(15,2),
    total_tax_amount numeric(15,2),
    total_invoice_value numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.invoice_summary OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16557)
-- Name: invoice_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_summary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_summary_id_seq OWNER TO postgres;

--
-- TOC entry 5245 (class 0 OID 0)
-- Dependencies: 240
-- Name: invoice_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_summary_id_seq OWNED BY public.invoice_summary.id;


--
-- TOC entry 241 (class 1259 OID 16558)
-- Name: invoice_supplier_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_supplier_details (
    id integer NOT NULL,
    invoice_id integer,
    pan_supplier character varying(20),
    gstin_supplier character varying(50),
    udyam_regno character varying(100),
    state character varying(100),
    state_code character varying(10),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    supplier_name character varying(255),
    supplier_address text
);


ALTER TABLE public.invoice_supplier_details OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16565)
-- Name: invoice_supplier_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_supplier_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_supplier_details_id_seq OWNER TO postgres;

--
-- TOC entry 5246 (class 0 OID 0)
-- Dependencies: 242
-- Name: invoice_supplier_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_supplier_details_id_seq OWNED BY public.invoice_supplier_details.id;


--
-- TOC entry 243 (class 1259 OID 16566)
-- Name: mrn_buyer_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mrn_buyer_details (
    id integer NOT NULL,
    mrn_id integer,
    received_at text,
    received_address text,
    gstin_receiving_party character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.mrn_buyer_details OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16573)
-- Name: mrn_buyer_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mrn_buyer_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mrn_buyer_details_id_seq OWNER TO postgres;

--
-- TOC entry 5247 (class 0 OID 0)
-- Dependencies: 244
-- Name: mrn_buyer_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mrn_buyer_details_id_seq OWNED BY public.mrn_buyer_details.id;


--
-- TOC entry 245 (class 1259 OID 16574)
-- Name: mrn_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mrn_details (
    id integer NOT NULL,
    mrn_number character varying(100),
    mrn_date date,
    po_reference_number character varying(100),
    po_date date,
    ref_invoice_number character varying(100),
    ref_invoice_date date,
    info text,
    remarks text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    vendor_name character varying(255),
    supplier_gstin character varying(15),
    buyer_gstin character varying(15),
    delivery_location character varying(255),
    total_amount character varying(255)
);


ALTER TABLE public.mrn_details OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 16581)
-- Name: mrn_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mrn_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mrn_details_id_seq OWNER TO postgres;

--
-- TOC entry 5248 (class 0 OID 0)
-- Dependencies: 246
-- Name: mrn_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mrn_details_id_seq OWNED BY public.mrn_details.id;


--
-- TOC entry 247 (class 1259 OID 16582)
-- Name: mrn_lineitems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mrn_lineitems (
    item_id integer NOT NULL,
    mrn_id integer,
    item_name text,
    received_quantity numeric(10,2),
    hsn_sac character varying(50),
    uom character varying(20),
    mrp numeric(15,2),
    unit_price numeric(15,2),
    discount numeric(15,2),
    gross_amount numeric(15,2),
    net_amount numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    gst_rate character varying
);


ALTER TABLE public.mrn_lineitems OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 16589)
-- Name: mrn_lineitems_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mrn_lineitems_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mrn_lineitems_item_id_seq OWNER TO postgres;

--
-- TOC entry 5249 (class 0 OID 0)
-- Dependencies: 248
-- Name: mrn_lineitems_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mrn_lineitems_item_id_seq OWNED BY public.mrn_lineitems.item_id;


--
-- TOC entry 249 (class 1259 OID 16590)
-- Name: mrn_summary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mrn_summary (
    id integer NOT NULL,
    mrn_id integer,
    cgst numeric(15,2),
    sgst numeric(15,2),
    igst numeric(15,2),
    gst_amount numeric(15,2),
    cess numeric(15,2),
    total_qty numeric(10,2),
    total_value numeric(20,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.mrn_summary OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 16595)
-- Name: mrn_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mrn_summary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mrn_summary_id_seq OWNER TO postgres;

--
-- TOC entry 5250 (class 0 OID 0)
-- Dependencies: 250
-- Name: mrn_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mrn_summary_id_seq OWNED BY public.mrn_summary.id;


--
-- TOC entry 251 (class 1259 OID 16596)
-- Name: mrn_supplier_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mrn_supplier_details (
    id integer NOT NULL,
    mrn_id integer,
    supplier_name text,
    supplier_address text,
    gstin_supplier character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.mrn_supplier_details OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 16603)
-- Name: mrn_supplier_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mrn_supplier_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mrn_supplier_details_id_seq OWNER TO postgres;

--
-- TOC entry 5251 (class 0 OID 0)
-- Dependencies: 252
-- Name: mrn_supplier_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mrn_supplier_details_id_seq OWNED BY public.mrn_supplier_details.id;


--
-- TOC entry 253 (class 1259 OID 16604)
-- Name: pdf_conversion_hypotus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pdf_conversion_hypotus (
    id integer NOT NULL,
    claim_id character varying(255) NOT NULL,
    num_pdfs integer NOT NULL,
    num_images integer NOT NULL,
    status character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    batchid bigint
);


ALTER TABLE public.pdf_conversion_hypotus OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 16608)
-- Name: pdf_conversion_hypotus_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pdf_conversion_hypotus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pdf_conversion_hypotus_id_seq OWNER TO postgres;

--
-- TOC entry 5252 (class 0 OID 0)
-- Dependencies: 254
-- Name: pdf_conversion_hypotus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pdf_conversion_hypotus_id_seq OWNED BY public.pdf_conversion_hypotus.id;


--
-- TOC entry 255 (class 1259 OID 16609)
-- Name: po_billto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.po_billto (
    id integer NOT NULL,
    po_id integer,
    bill_to character varying(255),
    billing_address text,
    gstin_buyer character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.po_billto OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 16616)
-- Name: po_billto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.po_billto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.po_billto_id_seq OWNER TO postgres;

--
-- TOC entry 5253 (class 0 OID 0)
-- Dependencies: 256
-- Name: po_billto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.po_billto_id_seq OWNED BY public.po_billto.id;


--
-- TOC entry 257 (class 1259 OID 16617)
-- Name: po_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.po_details (
    po_id integer NOT NULL,
    po_number character varying(100),
    po_date date,
    total_amount numeric(15,2),
    vendor_ref character varying(255),
    delivery_terms text,
    payment_term text,
    shipment_mode character varying(100),
    warranty_period character varying(100),
    delivery_period character varying(100),
    contact_person character varying(100),
    mobile character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    item_code character varying,
    vendor_name character varying(255),
    supplier_gstin character varying(15),
    buyer_gstin character varying(15),
    delivery_location character varying(255)
);


ALTER TABLE public.po_details OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 16624)
-- Name: po_details_po_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.po_details_po_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.po_details_po_id_seq OWNER TO postgres;

--
-- TOC entry 5254 (class 0 OID 0)
-- Dependencies: 258
-- Name: po_details_po_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.po_details_po_id_seq OWNED BY public.po_details.po_id;


--
-- TOC entry 259 (class 1259 OID 16625)
-- Name: po_lineitems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.po_lineitems (
    item_id integer NOT NULL,
    po_id integer NOT NULL,
    item_name character varying(255),
    oem_part_code character varying(100),
    quantity numeric(15,2),
    uom character varying(50),
    unit_price numeric(15,2),
    discount numeric(15,2),
    taxable numeric(15,2),
    gst_rate numeric(5,2),
    gst_amount numeric(15,2),
    billable_value numeric(15,2),
    total_qty numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.po_lineitems OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 16630)
-- Name: po_line_items_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.po_line_items_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.po_line_items_item_id_seq OWNER TO postgres;

--
-- TOC entry 5255 (class 0 OID 0)
-- Dependencies: 260
-- Name: po_line_items_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.po_line_items_item_id_seq OWNED BY public.po_lineitems.item_id;


--
-- TOC entry 261 (class 1259 OID 16631)
-- Name: po_shipping_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.po_shipping_details (
    id integer NOT NULL,
    po_id integer,
    ship_to character varying(255),
    shipping_address text,
    gstin_buyer character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.po_shipping_details OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 16638)
-- Name: po_shipping_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.po_shipping_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.po_shipping_details_id_seq OWNER TO postgres;

--
-- TOC entry 5256 (class 0 OID 0)
-- Dependencies: 262
-- Name: po_shipping_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.po_shipping_details_id_seq OWNED BY public.po_shipping_details.id;


--
-- TOC entry 263 (class 1259 OID 16639)
-- Name: po_summary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.po_summary (
    id integer NOT NULL,
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
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.po_summary OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 16644)
-- Name: po_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.po_summary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.po_summary_id_seq OWNER TO postgres;

--
-- TOC entry 5257 (class 0 OID 0)
-- Dependencies: 264
-- Name: po_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.po_summary_id_seq OWNED BY public.po_summary.id;


--
-- TOC entry 265 (class 1259 OID 16645)
-- Name: po_supplier_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.po_supplier_details (
    id integer NOT NULL,
    po_id integer,
    supplier_name character varying(255),
    supplier_code character varying(255),
    gstin_supplier character varying(50),
    supplier_address text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.po_supplier_details OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 16652)
-- Name: po_supplier_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.po_supplier_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.po_supplier_details_id_seq OWNER TO postgres;

--
-- TOC entry 5258 (class 0 OID 0)
-- Dependencies: 266
-- Name: po_supplier_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.po_supplier_details_id_seq OWNED BY public.po_supplier_details.id;


--
-- TOC entry 267 (class 1259 OID 16653)
-- Name: po_terms_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.po_terms_conditions (
    id integer NOT NULL,
    po_id integer,
    terms_conditions text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.po_terms_conditions OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 16660)
-- Name: po_terms_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.po_terms_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.po_terms_conditions_id_seq OWNER TO postgres;

--
-- TOC entry 5259 (class 0 OID 0)
-- Dependencies: 268
-- Name: po_terms_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.po_terms_conditions_id_seq OWNED BY public.po_terms_conditions.id;


--
-- TOC entry 269 (class 1259 OID 16661)
-- Name: purchase_order_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.purchase_order_details (
    id integer NOT NULL,
    batch_id character varying(100) NOT NULL,
    po_no character varying(100) NOT NULL,
    po_date date,
    vendor_ref character varying(150),
    delivery_terms character varying(255),
    payment_terms character varying(255),
    shipment_mode character varying(150),
    warranty_period character varying(150),
    delivery_period character varying(150),
    contact_person character varying(150),
    mobile_number character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.purchase_order_details OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 16668)
-- Name: purchase_order_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.purchase_order_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.purchase_order_details_id_seq OWNER TO postgres;

--
-- TOC entry 5260 (class 0 OID 0)
-- Dependencies: 270
-- Name: purchase_order_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.purchase_order_details_id_seq OWNED BY public.purchase_order_details.id;


--
-- TOC entry 271 (class 1259 OID 16669)
-- Name: rao_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rao_details (
    rao_id integer NOT NULL,
    rao_number character varying(100),
    rao_date date,
    po_reference_number character varying(100),
    po_date date,
    ref_invoice_number character varying(100),
    ref_invoice_date date,
    document_title text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.rao_details OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 16676)
-- Name: rao_details_rao_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rao_details_rao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rao_details_rao_id_seq OWNER TO postgres;

--
-- TOC entry 5261 (class 0 OID 0)
-- Dependencies: 272
-- Name: rao_details_rao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rao_details_rao_id_seq OWNED BY public.rao_details.rao_id;


--
-- TOC entry 273 (class 1259 OID 16677)
-- Name: rao_lineitems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rao_lineitems (
    item_id integer NOT NULL,
    rao_id integer,
    item_name text,
    received_quantity numeric(10,2),
    hsn_sac character varying(50),
    unit_price numeric(15,2),
    discount numeric(15,2),
    gst_rate numeric(5,2),
    total_value numeric(20,2),
    engine_no character varying(100),
    chasis_no character varying(100),
    serial_no character varying(100),
    asset_id character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.rao_lineitems OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 16684)
-- Name: rao_lineitems_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rao_lineitems_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rao_lineitems_item_id_seq OWNER TO postgres;

--
-- TOC entry 5262 (class 0 OID 0)
-- Dependencies: 274
-- Name: rao_lineitems_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rao_lineitems_item_id_seq OWNED BY public.rao_lineitems.item_id;


--
-- TOC entry 275 (class 1259 OID 16685)
-- Name: rao_receivedat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rao_receivedat (
    id integer NOT NULL,
    rao_id integer,
    received_date date,
    received_at text,
    received_address text,
    gstin_receiving_party character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.rao_receivedat OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 16692)
-- Name: rao_receivedat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rao_receivedat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rao_receivedat_id_seq OWNER TO postgres;

--
-- TOC entry 5263 (class 0 OID 0)
-- Dependencies: 276
-- Name: rao_receivedat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rao_receivedat_id_seq OWNED BY public.rao_receivedat.id;


--
-- TOC entry 277 (class 1259 OID 16693)
-- Name: rao_summary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rao_summary (
    id integer NOT NULL,
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
    gross_amount character varying,
    sub_total character varying
);


ALTER TABLE public.rao_summary OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 16700)
-- Name: rao_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rao_summary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rao_summary_id_seq OWNER TO postgres;

--
-- TOC entry 5264 (class 0 OID 0)
-- Dependencies: 278
-- Name: rao_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rao_summary_id_seq OWNED BY public.rao_summary.id;


--
-- TOC entry 279 (class 1259 OID 16701)
-- Name: rao_supplier_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rao_supplier_details (
    id integer NOT NULL,
    rao_id integer,
    supplier_name text,
    supplier_address text,
    gstin_supplier character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.rao_supplier_details OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 16708)
-- Name: rao_supplier_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rao_supplier_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rao_supplier_details_id_seq OWNER TO postgres;

--
-- TOC entry 5265 (class 0 OID 0)
-- Dependencies: 280
-- Name: rao_supplier_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rao_supplier_details_id_seq OWNED BY public.rao_supplier_details.id;


--
-- TOC entry 281 (class 1259 OID 16709)
-- Name: vw_3way_matching_report; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_3way_matching_report AS
 SELECT pol.item_name,
        CASE
            WHEN (inv.item_name IS NULL) THEN 'Not Invoiced'::text
            WHEN (mrn.item_name IS NULL) THEN 'Not Received'::text
            WHEN ((lower((inv.item_name)::text) = lower(mrn.item_name)) AND (lower((inv.item_name)::text) = lower((pol.item_name)::text))) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS item_description_check,
        CASE
            WHEN ((inv.hsn IS NULL) OR (mrn.hsn_sac IS NULL)) THEN 'Not Available'::text
            WHEN (((inv.hsn)::text = (mrn.hsn_sac)::text) AND ((inv.hsn)::text = (pol.oem_part_code)::text)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS hsn_code_check,
        CASE
            WHEN ((inv.quantity IS NULL) OR (mrn.received_quantity IS NULL)) THEN 'Not Available'::text
            WHEN ((inv.quantity = pol.quantity) AND (mrn.received_quantity = pol.quantity)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS quantity_check,
        CASE
            WHEN ((inv.uom IS NULL) OR (mrn.uom IS NULL)) THEN 'Not Available'::text
            WHEN (((inv.uom)::text = (mrn.uom)::text) AND ((inv.uom)::text = (pol.uom)::text)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS uom_check,
        CASE
            WHEN (inv.unit_price IS NULL) THEN 'Not Invoiced'::text
            WHEN (inv.unit_price = pol.unit_price) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS unit_price_check,
        CASE
            WHEN ((inv.unit_price IS NULL) OR (inv.rate_incl_of_tax IS NULL)) THEN 'Not Invoiced'::text
            WHEN (round((inv.rate_incl_of_tax - inv.unit_price), 2) = pol.gst_rate) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS gst_rate_check,
        CASE
            WHEN ((inv.total_value IS NULL) OR (inv.total_taxable_amount IS NULL)) THEN 'Not Invoiced'::text
            WHEN (round((inv.total_value - inv.total_taxable_amount), 2) = round(((inv.total_taxable_amount * pol.gst_rate) / (100)::numeric), 2)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS tax_amount_check,
        CASE
            WHEN (inv.total_value IS NULL) THEN 'Not Invoiced'::text
            WHEN (round(inv.total_value, 2) = round(pol.billable_value, 2)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS total_amount_check,
        CASE
            WHEN ((pod.vendor_ref IS NULL) OR (ind.batch_id IS NULL)) THEN 'Not Available'::text
            WHEN ((pod.vendor_ref)::text = (ind.batch_id)::text) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS supplier_gstin_check,
        CASE
            WHEN ((pod.contact_person IS NULL) OR (ind.created_at IS NULL)) THEN 'Not Available'::text
            WHEN ((pod.contact_person)::text = (ind.created_at)::text) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS buyer_gstin_check,
        CASE
            WHEN (ind.invoice_number IS NOT NULL) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS invoice_number_check,
        CASE
            WHEN (((pod.po_number)::text = (ind.po_ref)::text) AND ((pod.po_number)::text = (mrnd.po_reference_number)::text)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS po_number_check,
        CASE
            WHEN (ind.invoice_date >= pod.po_date) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS date_timeline_check,
        CASE
            WHEN ((pol.uom IS NOT NULL) AND (mrn.uom IS NOT NULL)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS delivery_location_check,
    'Optional'::text AS transport_details_check,
        CASE
            WHEN ((mrnd.mrn_number IS NOT NULL) AND (mrnd.mrn_date IS NOT NULL)) THEN 'Match'::text
            ELSE 'Mismatch'::text
        END AS mrn_number_date_check
   FROM (((((public.po_lineitems pol
     LEFT JOIN public.po_details pod ON ((pol.po_id = pod.po_id)))
     LEFT JOIN public.invoice_details ind ON (((ind.po_ref)::text = (pod.po_number)::text)))
     LEFT JOIN public.invoice_lineitems inv ON (((inv.invoice_id = ind.invoice_id) AND (lower((inv.item_name)::text) = lower((pol.item_name)::text)))))
     LEFT JOIN public.mrn_details mrnd ON (((mrnd.po_reference_number)::text = (pod.po_number)::text)))
     LEFT JOIN public.mrn_lineitems mrn ON (((mrn.mrn_id = mrnd.id) AND (lower(mrn.item_name) = lower((pol.item_name)::text)))));


ALTER VIEW public.vw_3way_matching_report OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 16714)
-- Name: vw_combined_transaction_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_combined_transaction_summary AS
 SELECT pod.po_number,
    ind.invoice_id,
    ind.invoice_number,
    mrnd.mrn_number,
    pos.total_qty AS po_total_qty,
    pos.total_rate AS po_total_rate,
    pos.total_discount AS po_total_discount,
    pos.total_taxable_amount AS po_taxable,
    pos.total_gst_amt AS po_total_gst,
    pos.total_billable_value AS po_total_billable,
    pos.total_purchase_order_amount AS po_total_value,
    invs.total_discount_value AS invoice_total_discount,
    invs.total_quantity AS invoice_total_qty,
    invs.total_taxable_amount AS invoice_taxable,
    invs.total_cgst_amount AS invoice_cgst,
    invs.total_sgst_amount AS invoice_sgst,
    invs.total_tax_amount AS invoice_total_tax,
    invs.total_invoice_value AS invoice_total_value,
    mrns.total_qty AS mrn_total_qty,
    mrns.cgst AS mrn_cgst,
    mrns.sgst AS mrn_sgst,
    mrns.igst AS mrn_igst,
    mrns.gst_amount AS mrn_total_gst,
    mrns.total_value AS mrn_total_value
   FROM (((((public.po_details pod
     LEFT JOIN public.po_summary pos ON ((pos.po_id = pod.po_id)))
     LEFT JOIN public.invoice_details ind ON (((ind.po_ref)::text = (pod.po_number)::text)))
     LEFT JOIN public.invoice_summary invs ON ((invs.invoice_id = ind.invoice_id)))
     LEFT JOIN public.mrn_details mrnd ON (((mrnd.po_reference_number)::text = (pod.po_number)::text)))
     LEFT JOIN public.mrn_summary mrns ON ((mrns.mrn_id = mrnd.id)));


ALTER VIEW public.vw_combined_transaction_summary OWNER TO postgres;

--
-- TOC entry 4911 (class 2604 OID 16719)
-- Name: hypotus_bbox id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hypotus_bbox ALTER COLUMN id SET DEFAULT nextval('public.hypotus_bbox_id_seq'::regclass);


--
-- TOC entry 4913 (class 2604 OID 16720)
-- Name: image_classification_hypotus id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_classification_hypotus ALTER COLUMN id SET DEFAULT nextval('public.image_classification_hypotus_id_seq'::regclass);


--
-- TOC entry 4914 (class 2604 OID 16721)
-- Name: image_duplicates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_duplicates ALTER COLUMN id SET DEFAULT nextval('public.image_duplicates_id_seq'::regclass);


--
-- TOC entry 4916 (class 2604 OID 16722)
-- Name: invoice_asset_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_asset_details ALTER COLUMN id SET DEFAULT nextval('public.invoice_asset_details_id_seq'::regclass);


--
-- TOC entry 4919 (class 2604 OID 16723)
-- Name: invoice_bank_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_bank_details ALTER COLUMN id SET DEFAULT nextval('public.invoice_bank_details_id_seq'::regclass);


--
-- TOC entry 4922 (class 2604 OID 16724)
-- Name: invoice_buyer_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_buyer_details ALTER COLUMN id SET DEFAULT nextval('public.invoice_buyer_details_id_seq'::regclass);


--
-- TOC entry 4925 (class 2604 OID 16725)
-- Name: invoice_check_list id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_check_list ALTER COLUMN id SET DEFAULT nextval('public.invoice_check_list_id_seq'::regclass);


--
-- TOC entry 4928 (class 2604 OID 16726)
-- Name: invoice_details invoice_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_details ALTER COLUMN invoice_id SET DEFAULT nextval('public.invoice_details_invoice_id_seq'::regclass);


--
-- TOC entry 4931 (class 2604 OID 16727)
-- Name: invoice_lineitems item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_lineitems ALTER COLUMN item_id SET DEFAULT nextval('public.invoice_lineitems_item_id_seq'::regclass);


--
-- TOC entry 4935 (class 2604 OID 16728)
-- Name: invoice_shipping_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_shipping_details ALTER COLUMN id SET DEFAULT nextval('public.invoice_shipping_details_id_seq'::regclass);


--
-- TOC entry 4938 (class 2604 OID 16729)
-- Name: invoice_summary id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_summary ALTER COLUMN id SET DEFAULT nextval('public.invoice_summary_id_seq'::regclass);


--
-- TOC entry 4941 (class 2604 OID 16730)
-- Name: invoice_supplier_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_supplier_details ALTER COLUMN id SET DEFAULT nextval('public.invoice_supplier_details_id_seq'::regclass);


--
-- TOC entry 4944 (class 2604 OID 16731)
-- Name: mrn_buyer_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_buyer_details ALTER COLUMN id SET DEFAULT nextval('public.mrn_buyer_details_id_seq'::regclass);


--
-- TOC entry 4947 (class 2604 OID 16732)
-- Name: mrn_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_details ALTER COLUMN id SET DEFAULT nextval('public.mrn_details_id_seq'::regclass);


--
-- TOC entry 4950 (class 2604 OID 16733)
-- Name: mrn_lineitems item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_lineitems ALTER COLUMN item_id SET DEFAULT nextval('public.mrn_lineitems_item_id_seq'::regclass);


--
-- TOC entry 4953 (class 2604 OID 16734)
-- Name: mrn_summary id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_summary ALTER COLUMN id SET DEFAULT nextval('public.mrn_summary_id_seq'::regclass);


--
-- TOC entry 4956 (class 2604 OID 16735)
-- Name: mrn_supplier_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_supplier_details ALTER COLUMN id SET DEFAULT nextval('public.mrn_supplier_details_id_seq'::regclass);


--
-- TOC entry 4959 (class 2604 OID 16736)
-- Name: pdf_conversion_hypotus id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdf_conversion_hypotus ALTER COLUMN id SET DEFAULT nextval('public.pdf_conversion_hypotus_id_seq'::regclass);


--
-- TOC entry 4961 (class 2604 OID 16737)
-- Name: po_billto id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_billto ALTER COLUMN id SET DEFAULT nextval('public.po_billto_id_seq'::regclass);


--
-- TOC entry 4964 (class 2604 OID 16738)
-- Name: po_details po_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_details ALTER COLUMN po_id SET DEFAULT nextval('public.po_details_po_id_seq'::regclass);


--
-- TOC entry 4967 (class 2604 OID 16739)
-- Name: po_lineitems item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_lineitems ALTER COLUMN item_id SET DEFAULT nextval('public.po_line_items_item_id_seq'::regclass);


--
-- TOC entry 4970 (class 2604 OID 16740)
-- Name: po_shipping_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_shipping_details ALTER COLUMN id SET DEFAULT nextval('public.po_shipping_details_id_seq'::regclass);


--
-- TOC entry 4973 (class 2604 OID 16741)
-- Name: po_summary id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_summary ALTER COLUMN id SET DEFAULT nextval('public.po_summary_id_seq'::regclass);


--
-- TOC entry 4976 (class 2604 OID 16742)
-- Name: po_supplier_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_supplier_details ALTER COLUMN id SET DEFAULT nextval('public.po_supplier_details_id_seq'::regclass);


--
-- TOC entry 4979 (class 2604 OID 16743)
-- Name: po_terms_conditions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_terms_conditions ALTER COLUMN id SET DEFAULT nextval('public.po_terms_conditions_id_seq'::regclass);


--
-- TOC entry 4982 (class 2604 OID 16744)
-- Name: purchase_order_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_order_details ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_details_id_seq'::regclass);


--
-- TOC entry 4985 (class 2604 OID 16745)
-- Name: rao_details rao_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_details ALTER COLUMN rao_id SET DEFAULT nextval('public.rao_details_rao_id_seq'::regclass);


--
-- TOC entry 4988 (class 2604 OID 16746)
-- Name: rao_lineitems item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_lineitems ALTER COLUMN item_id SET DEFAULT nextval('public.rao_lineitems_item_id_seq'::regclass);


--
-- TOC entry 4991 (class 2604 OID 16747)
-- Name: rao_receivedat id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_receivedat ALTER COLUMN id SET DEFAULT nextval('public.rao_receivedat_id_seq'::regclass);


--
-- TOC entry 4994 (class 2604 OID 16748)
-- Name: rao_summary id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_summary ALTER COLUMN id SET DEFAULT nextval('public.rao_summary_id_seq'::regclass);


--
-- TOC entry 4997 (class 2604 OID 16749)
-- Name: rao_supplier_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_supplier_details ALTER COLUMN id SET DEFAULT nextval('public.rao_supplier_details_id_seq'::regclass);


--
-- TOC entry 5001 (class 2606 OID 16767)
-- Name: hypotus_bbox hypotus_bbox_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hypotus_bbox
    ADD CONSTRAINT hypotus_bbox_pkey PRIMARY KEY (id);


--
-- TOC entry 5003 (class 2606 OID 16769)
-- Name: image_classification_hypotus image_classification_hypotus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_classification_hypotus
    ADD CONSTRAINT image_classification_hypotus_pkey PRIMARY KEY (id);


--
-- TOC entry 5005 (class 2606 OID 16771)
-- Name: image_duplicates image_duplicates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_duplicates
    ADD CONSTRAINT image_duplicates_pkey PRIMARY KEY (id);


--
-- TOC entry 5007 (class 2606 OID 16773)
-- Name: invoice_asset_details invoice_asset_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_asset_details
    ADD CONSTRAINT invoice_asset_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5009 (class 2606 OID 16775)
-- Name: invoice_bank_details invoice_bank_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_bank_details
    ADD CONSTRAINT invoice_bank_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5011 (class 2606 OID 16777)
-- Name: invoice_buyer_details invoice_buyer_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_buyer_details
    ADD CONSTRAINT invoice_buyer_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5013 (class 2606 OID 16779)
-- Name: invoice_check_list invoice_check_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_check_list
    ADD CONSTRAINT invoice_check_list_pkey PRIMARY KEY (id);


--
-- TOC entry 5015 (class 2606 OID 16781)
-- Name: invoice_details invoice_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_details
    ADD CONSTRAINT invoice_details_pkey PRIMARY KEY (invoice_id);


--
-- TOC entry 5017 (class 2606 OID 16783)
-- Name: invoice_lineitems invoice_lineitems_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_lineitems
    ADD CONSTRAINT invoice_lineitems_pkey PRIMARY KEY (item_id);


--
-- TOC entry 5019 (class 2606 OID 16785)
-- Name: invoice_shipping_details invoice_shipping_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_shipping_details
    ADD CONSTRAINT invoice_shipping_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5021 (class 2606 OID 16787)
-- Name: invoice_summary invoice_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_summary
    ADD CONSTRAINT invoice_summary_pkey PRIMARY KEY (id);


--
-- TOC entry 5023 (class 2606 OID 16789)
-- Name: invoice_supplier_details invoice_supplier_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_supplier_details
    ADD CONSTRAINT invoice_supplier_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5025 (class 2606 OID 16791)
-- Name: mrn_buyer_details mrn_buyer_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_buyer_details
    ADD CONSTRAINT mrn_buyer_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5027 (class 2606 OID 16793)
-- Name: mrn_details mrn_details_mrn_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_details
    ADD CONSTRAINT mrn_details_mrn_number_key UNIQUE (mrn_number);


--
-- TOC entry 5029 (class 2606 OID 16795)
-- Name: mrn_details mrn_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_details
    ADD CONSTRAINT mrn_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5031 (class 2606 OID 16797)
-- Name: mrn_lineitems mrn_lineitems_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_lineitems
    ADD CONSTRAINT mrn_lineitems_pkey PRIMARY KEY (item_id);


--
-- TOC entry 5033 (class 2606 OID 16799)
-- Name: mrn_summary mrn_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_summary
    ADD CONSTRAINT mrn_summary_pkey PRIMARY KEY (id);


--
-- TOC entry 5035 (class 2606 OID 16801)
-- Name: mrn_supplier_details mrn_supplier_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_supplier_details
    ADD CONSTRAINT mrn_supplier_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5037 (class 2606 OID 16803)
-- Name: pdf_conversion_hypotus pdf_conversion_hypotus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdf_conversion_hypotus
    ADD CONSTRAINT pdf_conversion_hypotus_pkey PRIMARY KEY (id);


--
-- TOC entry 5039 (class 2606 OID 16805)
-- Name: po_billto po_billto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_billto
    ADD CONSTRAINT po_billto_pkey PRIMARY KEY (id);


--
-- TOC entry 5041 (class 2606 OID 16807)
-- Name: po_details po_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_details
    ADD CONSTRAINT po_details_pkey PRIMARY KEY (po_id);


--
-- TOC entry 5043 (class 2606 OID 16809)
-- Name: po_lineitems po_line_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_lineitems
    ADD CONSTRAINT po_line_items_pkey PRIMARY KEY (item_id);


--
-- TOC entry 5045 (class 2606 OID 16811)
-- Name: po_shipping_details po_shipping_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_shipping_details
    ADD CONSTRAINT po_shipping_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5047 (class 2606 OID 16813)
-- Name: po_summary po_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_summary
    ADD CONSTRAINT po_summary_pkey PRIMARY KEY (id);


--
-- TOC entry 5049 (class 2606 OID 16815)
-- Name: po_supplier_details po_supplier_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_supplier_details
    ADD CONSTRAINT po_supplier_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5051 (class 2606 OID 16817)
-- Name: po_terms_conditions po_terms_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_terms_conditions
    ADD CONSTRAINT po_terms_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 5053 (class 2606 OID 16819)
-- Name: purchase_order_details purchase_order_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_order_details
    ADD CONSTRAINT purchase_order_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5055 (class 2606 OID 16821)
-- Name: purchase_order_details purchase_order_details_po_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_order_details
    ADD CONSTRAINT purchase_order_details_po_no_key UNIQUE (po_no);


--
-- TOC entry 5057 (class 2606 OID 16823)
-- Name: rao_details rao_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_details
    ADD CONSTRAINT rao_details_pkey PRIMARY KEY (rao_id);


--
-- TOC entry 5059 (class 2606 OID 16825)
-- Name: rao_lineitems rao_lineitems_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_lineitems
    ADD CONSTRAINT rao_lineitems_pkey PRIMARY KEY (item_id);


--
-- TOC entry 5061 (class 2606 OID 16827)
-- Name: rao_receivedat rao_receivedat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_receivedat
    ADD CONSTRAINT rao_receivedat_pkey PRIMARY KEY (id);


--
-- TOC entry 5063 (class 2606 OID 16829)
-- Name: rao_summary rao_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_summary
    ADD CONSTRAINT rao_summary_pkey PRIMARY KEY (id);


--
-- TOC entry 5065 (class 2606 OID 16831)
-- Name: rao_supplier_details rao_supplier_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_supplier_details
    ADD CONSTRAINT rao_supplier_details_pkey PRIMARY KEY (id);


--
-- TOC entry 5066 (class 2606 OID 16832)
-- Name: invoice_buyer_details invoice_buyer_details_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_buyer_details
    ADD CONSTRAINT invoice_buyer_details_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_details(invoice_id) ON DELETE CASCADE;


--
-- TOC entry 5067 (class 2606 OID 16837)
-- Name: invoice_lineitems invoice_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_lineitems
    ADD CONSTRAINT invoice_id FOREIGN KEY (invoice_id) REFERENCES public.invoice_details(invoice_id) NOT VALID;


--
-- TOC entry 5068 (class 2606 OID 16842)
-- Name: invoice_summary invoice_summary_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_summary
    ADD CONSTRAINT invoice_summary_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_details(invoice_id) ON DELETE CASCADE;


--
-- TOC entry 5069 (class 2606 OID 16847)
-- Name: invoice_supplier_details invoice_supplier_details_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_supplier_details
    ADD CONSTRAINT invoice_supplier_details_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice_details(invoice_id) ON DELETE CASCADE;


--
-- TOC entry 5070 (class 2606 OID 16852)
-- Name: mrn_buyer_details mrn_buyer_details_mrn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_buyer_details
    ADD CONSTRAINT mrn_buyer_details_mrn_id_fkey FOREIGN KEY (mrn_id) REFERENCES public.mrn_details(id) ON DELETE CASCADE;


--
-- TOC entry 5071 (class 2606 OID 16857)
-- Name: mrn_lineitems mrn_lineitems_mrn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_lineitems
    ADD CONSTRAINT mrn_lineitems_mrn_id_fkey FOREIGN KEY (mrn_id) REFERENCES public.mrn_details(id) ON DELETE CASCADE;


--
-- TOC entry 5072 (class 2606 OID 16862)
-- Name: mrn_summary mrn_summary_mrn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_summary
    ADD CONSTRAINT mrn_summary_mrn_id_fkey FOREIGN KEY (mrn_id) REFERENCES public.mrn_details(id) ON DELETE CASCADE;


--
-- TOC entry 5073 (class 2606 OID 16867)
-- Name: mrn_supplier_details mrn_supplier_details_mrn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mrn_supplier_details
    ADD CONSTRAINT mrn_supplier_details_mrn_id_fkey FOREIGN KEY (mrn_id) REFERENCES public.mrn_details(id) ON DELETE CASCADE;


--
-- TOC entry 5074 (class 2606 OID 16872)
-- Name: po_billto po_billto_po_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_billto
    ADD CONSTRAINT po_billto_po_id_fkey FOREIGN KEY (po_id) REFERENCES public.po_details(po_id) ON DELETE CASCADE;


--
-- TOC entry 5075 (class 2606 OID 16877)
-- Name: po_shipping_details po_shipping_details_po_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_shipping_details
    ADD CONSTRAINT po_shipping_details_po_id_fkey FOREIGN KEY (po_id) REFERENCES public.po_details(po_id) ON DELETE CASCADE;


--
-- TOC entry 5076 (class 2606 OID 16882)
-- Name: po_supplier_details po_supplier_details_po_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_supplier_details
    ADD CONSTRAINT po_supplier_details_po_id_fkey FOREIGN KEY (po_id) REFERENCES public.po_details(po_id) ON DELETE CASCADE;


--
-- TOC entry 5077 (class 2606 OID 16887)
-- Name: po_terms_conditions po_terms_conditions_po_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.po_terms_conditions
    ADD CONSTRAINT po_terms_conditions_po_id_fkey FOREIGN KEY (po_id) REFERENCES public.po_details(po_id) ON DELETE CASCADE;


--
-- TOC entry 5078 (class 2606 OID 16892)
-- Name: rao_lineitems rao_lineitems_rao_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_lineitems
    ADD CONSTRAINT rao_lineitems_rao_id_fkey FOREIGN KEY (rao_id) REFERENCES public.rao_details(rao_id) ON DELETE CASCADE;


--
-- TOC entry 5079 (class 2606 OID 16897)
-- Name: rao_receivedat rao_receivedat_grn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_receivedat
    ADD CONSTRAINT rao_receivedat_grn_id_fkey FOREIGN KEY (rao_id) REFERENCES public.rao_details(rao_id) ON DELETE CASCADE;


--
-- TOC entry 5080 (class 2606 OID 16902)
-- Name: rao_summary rao_summary_rao_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_summary
    ADD CONSTRAINT rao_summary_rao_id_fkey FOREIGN KEY (rao_id) REFERENCES public.rao_details(rao_id) ON DELETE CASCADE;


--
-- TOC entry 5081 (class 2606 OID 16907)
-- Name: rao_supplier_details rao_supplier_details_rao_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rao_supplier_details
    ADD CONSTRAINT rao_supplier_details_rao_id_fkey FOREIGN KEY (rao_id) REFERENCES public.rao_details(rao_id) ON DELETE CASCADE;


-- Completed on 2025-08-05 14:23:27

--
-- PostgreSQL database dump complete
--

