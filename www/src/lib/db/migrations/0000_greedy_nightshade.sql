CREATE TYPE "public"."company_role" AS ENUM('owner', 'admin', 'member');--> statement-breakpoint
CREATE TYPE "public"."package_item_status" AS ENUM('draft', 'sent', 'quote_received', 'approved', 'confirmed', 'unavailable', 'over_budget');--> statement-breakpoint
CREATE TYPE "public"."product_relationship_type" AS ENUM('requires', 'recommends', 'replaces', 'incompatible_with', 'optional_upgrade');--> statement-breakpoint
CREATE TYPE "public"."production_role" AS ENUM('dp', 'coordinator', 'producer', 'gaffer');--> statement-breakpoint
CREATE TYPE "public"."production_status" AS ENUM('draft', 'active', 'wrapped', 'archived');--> statement-breakpoint
CREATE TYPE "public"."rental_house_type" AS ENUM('full_service', 'specialty', 'peer_to_peer', 'manufacturer');--> statement-breakpoint
CREATE TABLE "account" (
	"id" text PRIMARY KEY NOT NULL,
	"account_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"user_id" uuid NOT NULL,
	"access_token" text,
	"refresh_token" text,
	"id_token" text,
	"access_token_expires_at" timestamp with time zone,
	"refresh_token_expires_at" timestamp with time zone,
	"scope" text,
	"password" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "brand" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"website_url" text,
	"logo_url" text,
	"scraping_enabled" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "brand_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "companies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text,
	"logo_url" text,
	"billing_email" text,
	"plan" text DEFAULT 'free' NOT NULL,
	"created_by" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "companies_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "company_members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"company_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" "company_role" NOT NULL,
	"invited_by" uuid,
	"joined_at" timestamp with time zone,
	CONSTRAINT "company_members_company_id_user_id_unique" UNIQUE("company_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "compatibility_axis" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"description" text,
	"value_type" text DEFAULT 'enum' NOT NULL,
	"display_order" integer DEFAULT 0,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "compatibility_axis_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "invitations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" text NOT NULL,
	"company_id" uuid NOT NULL,
	"production_id" uuid,
	"company_role" "company_role",
	"production_role" "production_role",
	"token" text NOT NULL,
	"invited_by" uuid,
	"expires_at" timestamp with time zone NOT NULL,
	"accepted_at" timestamp with time zone,
	CONSTRAINT "invitations_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "kit_template" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"anchor_product_id" uuid,
	"shoot_type" text,
	"description" text,
	"is_public" boolean DEFAULT false,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "kit_template_item" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"kit_template_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"quantity" integer DEFAULT 1 NOT NULL,
	"is_required" boolean DEFAULT true,
	"sort_order" integer DEFAULT 0,
	"notes" text
);
--> statement-breakpoint
CREATE TABLE "package_comment_mentions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"comment_id" uuid NOT NULL,
	"mentioned_user_id" uuid NOT NULL,
	CONSTRAINT "package_comment_mentions_comment_id_mentioned_user_id_unique" UNIQUE("comment_id","mentioned_user_id")
);
--> statement-breakpoint
CREATE TABLE "package_comments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"package_id" uuid NOT NULL,
	"author_id" uuid NOT NULL,
	"body" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "package_item_quote" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"package_item_id" uuid NOT NULL,
	"rental_house_id" uuid NOT NULL,
	"location_id" uuid,
	"day_rate" numeric(10, 2),
	"week_rate" numeric(10, 2),
	"is_available" boolean,
	"is_selected" boolean DEFAULT false,
	"rental_house_notes" text,
	"quoted_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "package_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"package_id" uuid NOT NULL,
	"gear_id" uuid,
	"quantity" integer DEFAULT 1 NOT NULL,
	"day_rate_snapshot" numeric(10, 2),
	"status" "package_item_status" DEFAULT 'draft' NOT NULL,
	"notes" text,
	"added_by" uuid,
	"approved_by" uuid,
	"approved_at" timestamp with time zone,
	"sort_order" integer,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "packages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"production_id" uuid NOT NULL,
	"name" text NOT NULL,
	"source_kit_template_id" uuid,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"brand_id" uuid NOT NULL,
	"category_id" uuid NOT NULL,
	"model" text NOT NULL,
	"full_name" text NOT NULL,
	"slug" text NOT NULL,
	"sku" text,
	"upc" text,
	"announce_date" date,
	"msrp_usd" numeric,
	"current_price_usd" numeric,
	"primary_image_url" text,
	"thumbnail_url" text,
	"manufacturer_url" text,
	"source_url" text,
	"raw_data" jsonb,
	"last_scraped_at" timestamp with time zone,
	"scraping_status" text DEFAULT 'pending',
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "product_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "product_category" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"parent_category_id" uuid,
	"display_order" integer DEFAULT 0,
	"icon_name" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "product_category_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "product_compatibility_value" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"axis_id" uuid NOT NULL,
	"value" text NOT NULL,
	"is_input" boolean DEFAULT true,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "product_compatibility_value_product_id_axis_id_value_unique" UNIQUE("product_id","axis_id","value")
);
--> statement-breakpoint
CREATE TABLE "product_document" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid,
	"brand_slug" text,
	"product_type" text,
	"product_slug" text,
	"document_kind" text NOT NULL,
	"title" text,
	"url" text NOT NULL,
	"source_url" text,
	"status" text DEFAULT 'discovered',
	"discovered_at" timestamp with time zone DEFAULT now(),
	"downloaded_at" timestamp with time zone,
	"local_path" text,
	"raw_metadata" jsonb
);
--> statement-breakpoint
CREATE TABLE "product_image" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"url" text NOT NULL,
	"kind" text,
	"sort_order" integer DEFAULT 0,
	"source_url" text,
	"source" jsonb,
	"raw_metadata" jsonb,
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "product_relationship" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"source_product_id" uuid NOT NULL,
	"target_product_id" uuid NOT NULL,
	"relationship_type" "product_relationship_type" NOT NULL,
	"is_conditional" boolean DEFAULT false,
	"condition_note" text,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "product_relationship_source_product_id_target_product_id_relationship_type_unique" UNIQUE("source_product_id","target_product_id","relationship_type")
);
--> statement-breakpoint
CREATE TABLE "product_spec" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"spec_definition_id" uuid NOT NULL,
	"spec_value" text,
	"raw_value" text,
	"raw_value_jsonb" jsonb,
	"numeric_value" numeric,
	"min_value" numeric,
	"max_value" numeric,
	"unit_used" text,
	"boolean_value" boolean,
	"extraction_confidence" double precision,
	"scraped_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "product_spec_matrix" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"spec_definition_id" uuid NOT NULL,
	"dims" jsonb NOT NULL,
	"value_text" text,
	"numeric_value" numeric,
	"unit_used" text,
	"width_px" integer,
	"height_px" integer,
	"is_available" boolean DEFAULT true NOT NULL,
	"is_inexact_proportion" boolean DEFAULT false NOT NULL,
	"notes" text,
	"extraction_confidence" double precision,
	"scraped_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "product_spec_matrix_product_id_spec_definition_id_dims_unique" UNIQUE("product_id","spec_definition_id","dims")
);
--> statement-breakpoint
CREATE TABLE "production_members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"production_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" "production_role" NOT NULL,
	"department" text,
	"invited_by" uuid,
	"joined_at" timestamp with time zone,
	CONSTRAINT "production_members_production_id_user_id_unique" UNIQUE("production_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "productions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"company_id" uuid NOT NULL,
	"name" text NOT NULL,
	"shoot_type" text,
	"shoot_days" integer,
	"start_date" date,
	"end_date" date,
	"total_budget" numeric(12, 2),
	"status" "production_status" DEFAULT 'draft' NOT NULL,
	"created_by" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "rental_house" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"website_url" text,
	"logo_url" text,
	"type" "rental_house_type" DEFAULT 'full_service' NOT NULL,
	"description" text,
	"brand_id" uuid,
	"contact_email" text,
	"phone" text,
	"is_active" boolean DEFAULT true,
	"scraping_enabled" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "rental_house_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "rental_house_inventory" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"rental_house_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"location_id" uuid,
	"day_rate" numeric(10, 2),
	"week_rate" numeric(10, 2),
	"rental_house_product_code" text,
	"rental_house_product_url" text,
	"quantity_on_hand" integer,
	"is_available" boolean DEFAULT true,
	"last_scraped_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "rental_house_inventory_rental_house_id_product_id_location_id_unique" UNIQUE("rental_house_id","product_id","location_id")
);
--> statement-breakpoint
CREATE TABLE "rental_house_location" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"rental_house_id" uuid NOT NULL,
	"city" text NOT NULL,
	"state_or_region" text,
	"country" text DEFAULT 'US' NOT NULL,
	"address_line_1" text,
	"phone" text,
	"email" text,
	"contact_email" text,
	"is_primary" boolean DEFAULT false,
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "session" (
	"id" text PRIMARY KEY NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"token" text NOT NULL,
	"ip_address" text,
	"user_agent" text,
	"user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "session_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "spec_definition" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"section_id" uuid,
	"display_name" text NOT NULL,
	"normalized_key" text NOT NULL,
	"data_type" text DEFAULT 'text',
	"unit" text,
	"category_id" uuid,
	"description" text,
	"importance" integer DEFAULT 0,
	CONSTRAINT "spec_definition_normalized_key_unique" UNIQUE("normalized_key")
);
--> statement-breakpoint
CREATE TABLE "spec_mapping" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"spec_definition_id" uuid NOT NULL,
	"extraction_pattern" text NOT NULL,
	"context_pattern" text,
	"manufacturer_key" text,
	"priority" integer DEFAULT 0,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "spec_section" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"section_name" text NOT NULL,
	"category_id" uuid,
	"display_order" integer DEFAULT 0,
	"parent_section_id" uuid,
	CONSTRAINT "spec_section_section_name_category_id_unique" UNIQUE("section_name","category_id")
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text DEFAULT '' NOT NULL,
	"email" text NOT NULL,
	"email_verified" boolean DEFAULT false NOT NULL,
	"image" text,
	"full_name" text,
	"avatar_url" text,
	"app_role" text DEFAULT 'user' NOT NULL,
	"experience_level" text,
	"default_production_role" "production_role",
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "verification" (
	"id" text PRIMARY KEY NOT NULL,
	"identifier" text NOT NULL,
	"value" text NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "waitlist_signup" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" text NOT NULL,
	"source" text DEFAULT 'landing',
	"referrer" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "waitlist_signup_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "account" ADD CONSTRAINT "account_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "companies" ADD CONSTRAINT "companies_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "company_members" ADD CONSTRAINT "company_members_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "company_members" ADD CONSTRAINT "company_members_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "company_members" ADD CONSTRAINT "company_members_invited_by_users_id_fk" FOREIGN KEY ("invited_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_production_id_productions_id_fk" FOREIGN KEY ("production_id") REFERENCES "public"."productions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_invited_by_users_id_fk" FOREIGN KEY ("invited_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "kit_template" ADD CONSTRAINT "kit_template_anchor_product_id_product_id_fk" FOREIGN KEY ("anchor_product_id") REFERENCES "public"."product"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "kit_template" ADD CONSTRAINT "kit_template_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "kit_template_item" ADD CONSTRAINT "kit_template_item_kit_template_id_kit_template_id_fk" FOREIGN KEY ("kit_template_id") REFERENCES "public"."kit_template"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "kit_template_item" ADD CONSTRAINT "kit_template_item_product_id_product_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."product"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_comment_mentions" ADD CONSTRAINT "package_comment_mentions_comment_id_package_comments_id_fk" FOREIGN KEY ("comment_id") REFERENCES "public"."package_comments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_comment_mentions" ADD CONSTRAINT "package_comment_mentions_mentioned_user_id_users_id_fk" FOREIGN KEY ("mentioned_user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_comments" ADD CONSTRAINT "package_comments_package_id_packages_id_fk" FOREIGN KEY ("package_id") REFERENCES "public"."packages"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_comments" ADD CONSTRAINT "package_comments_author_id_users_id_fk" FOREIGN KEY ("author_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_item_quote" ADD CONSTRAINT "package_item_quote_package_item_id_package_items_id_fk" FOREIGN KEY ("package_item_id") REFERENCES "public"."package_items"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_item_quote" ADD CONSTRAINT "package_item_quote_rental_house_id_rental_house_id_fk" FOREIGN KEY ("rental_house_id") REFERENCES "public"."rental_house"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_item_quote" ADD CONSTRAINT "package_item_quote_location_id_rental_house_location_id_fk" FOREIGN KEY ("location_id") REFERENCES "public"."rental_house_location"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_items" ADD CONSTRAINT "package_items_package_id_packages_id_fk" FOREIGN KEY ("package_id") REFERENCES "public"."packages"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_items" ADD CONSTRAINT "package_items_gear_id_product_id_fk" FOREIGN KEY ("gear_id") REFERENCES "public"."product"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_items" ADD CONSTRAINT "package_items_added_by_users_id_fk" FOREIGN KEY ("added_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_items" ADD CONSTRAINT "package_items_approved_by_users_id_fk" FOREIGN KEY ("approved_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "packages" ADD CONSTRAINT "packages_production_id_productions_id_fk" FOREIGN KEY ("production_id") REFERENCES "public"."productions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "packages" ADD CONSTRAINT "packages_source_kit_template_id_kit_template_id_fk" FOREIGN KEY ("source_kit_template_id") REFERENCES "public"."kit_template"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "packages" ADD CONSTRAINT "packages_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_compatibility_value" ADD CONSTRAINT "product_compatibility_value_product_id_product_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."product"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_compatibility_value" ADD CONSTRAINT "product_compatibility_value_axis_id_compatibility_axis_id_fk" FOREIGN KEY ("axis_id") REFERENCES "public"."compatibility_axis"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_relationship" ADD CONSTRAINT "product_relationship_source_product_id_product_id_fk" FOREIGN KEY ("source_product_id") REFERENCES "public"."product"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_relationship" ADD CONSTRAINT "product_relationship_target_product_id_product_id_fk" FOREIGN KEY ("target_product_id") REFERENCES "public"."product"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_spec_matrix" ADD CONSTRAINT "product_spec_matrix_product_id_product_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."product"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_spec_matrix" ADD CONSTRAINT "product_spec_matrix_spec_definition_id_spec_definition_id_fk" FOREIGN KEY ("spec_definition_id") REFERENCES "public"."spec_definition"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "production_members" ADD CONSTRAINT "production_members_production_id_productions_id_fk" FOREIGN KEY ("production_id") REFERENCES "public"."productions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "production_members" ADD CONSTRAINT "production_members_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "production_members" ADD CONSTRAINT "production_members_invited_by_users_id_fk" FOREIGN KEY ("invited_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "productions" ADD CONSTRAINT "productions_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "productions" ADD CONSTRAINT "productions_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rental_house" ADD CONSTRAINT "rental_house_brand_id_brand_id_fk" FOREIGN KEY ("brand_id") REFERENCES "public"."brand"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rental_house_inventory" ADD CONSTRAINT "rental_house_inventory_rental_house_id_rental_house_id_fk" FOREIGN KEY ("rental_house_id") REFERENCES "public"."rental_house"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rental_house_inventory" ADD CONSTRAINT "rental_house_inventory_product_id_product_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."product"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rental_house_inventory" ADD CONSTRAINT "rental_house_inventory_location_id_rental_house_location_id_fk" FOREIGN KEY ("location_id") REFERENCES "public"."rental_house_location"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rental_house_location" ADD CONSTRAINT "rental_house_location_rental_house_id_rental_house_id_fk" FOREIGN KEY ("rental_house_id") REFERENCES "public"."rental_house"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "session" ADD CONSTRAINT "session_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "spec_mapping" ADD CONSTRAINT "spec_mapping_spec_definition_id_spec_definition_id_fk" FOREIGN KEY ("spec_definition_id") REFERENCES "public"."spec_definition"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "waitlist_signup_created_at_idx" ON "waitlist_signup" USING btree ("created_at");