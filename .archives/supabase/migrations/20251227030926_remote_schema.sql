drop extension if exists "pg_net";

drop trigger if exists "update_product_updated_at" on "public"."product";

alter table "public"."brand" drop constraint "brand_name_key";

alter table "public"."brand" drop constraint "brand_slug_key";

alter table "public"."product" drop constraint "product_brand_id_fkey";

alter table "public"."product" drop constraint "product_category_id_fkey";

alter table "public"."product" drop constraint "product_slug_key";

alter table "public"."product_category" drop constraint "product_category_parent_category_id_fkey";

alter table "public"."product_category" drop constraint "product_category_slug_key";

alter table "public"."product_spec" drop constraint "product_spec_product_id_fkey";

alter table "public"."product_spec" drop constraint "product_spec_product_id_spec_definition_id_key";

alter table "public"."product_spec" drop constraint "product_spec_spec_definition_id_fkey";

alter table "public"."product_spec_matrix" drop constraint "product_spec_matrix_product_id_fkey";

alter table "public"."product_spec_matrix" drop constraint "product_spec_matrix_product_id_spec_definition_id_dims_key";

alter table "public"."product_spec_matrix" drop constraint "product_spec_matrix_spec_definition_id_fkey";

alter table "public"."spec_definition" drop constraint "spec_definition_category_id_fkey";

alter table "public"."spec_definition" drop constraint "spec_definition_normalized_key_key";

alter table "public"."spec_definition" drop constraint "spec_definition_section_id_fkey";

alter table "public"."spec_mapping" drop constraint "spec_mapping_spec_definition_id_fkey";

alter table "public"."spec_section" drop constraint "spec_section_category_id_fkey";

alter table "public"."spec_section" drop constraint "spec_section_parent_section_id_fkey";

alter table "public"."spec_section" drop constraint "spec_section_section_name_category_id_key";

drop view if exists "public"."v_still_image_recording_pixels_grid";

alter table "public"."brand" drop constraint "brand_pkey";

alter table "public"."product" drop constraint "product_pkey";

alter table "public"."product_category" drop constraint "product_category_pkey";

alter table "public"."product_spec" drop constraint "product_spec_pkey";

alter table "public"."product_spec_matrix" drop constraint "product_spec_matrix_pkey";

alter table "public"."spec_definition" drop constraint "spec_definition_pkey";

alter table "public"."spec_mapping" drop constraint "spec_mapping_pkey";

alter table "public"."spec_section" drop constraint "spec_section_pkey";

drop index if exists "public"."brand_name_key";

drop index if exists "public"."brand_pkey";

drop index if exists "public"."brand_slug_key";

drop index if exists "public"."idx_product_brand";

drop index if exists "public"."idx_product_category";

drop index if exists "public"."idx_product_raw_data";

drop index if exists "public"."idx_product_slug";

drop index if exists "public"."idx_product_spec_definition";

drop index if exists "public"."idx_product_spec_numeric";

drop index if exists "public"."idx_product_spec_product";

drop index if exists "public"."idx_spec_mapping_pattern";

drop index if exists "public"."product_category_pkey";

drop index if exists "public"."product_category_slug_key";

drop index if exists "public"."product_pkey";

drop index if exists "public"."product_slug_key";

drop index if exists "public"."product_spec_matrix_pkey";

drop index if exists "public"."product_spec_matrix_product_id_spec_definition_id_dims_key";

drop index if exists "public"."product_spec_pkey";

drop index if exists "public"."product_spec_product_id_spec_definition_id_key";

drop index if exists "public"."spec_definition_normalized_key_key";

drop index if exists "public"."spec_definition_pkey";

drop index if exists "public"."spec_mapping_pkey";

drop index if exists "public"."spec_section_pkey";

drop index if exists "public"."spec_section_section_name_category_id_key";

CREATE UNIQUE INDEX brands_name_key ON public.brand USING btree (name);

CREATE UNIQUE INDEX brands_pkey ON public.brand USING btree (id);

CREATE UNIQUE INDEX brands_slug_key ON public.brand USING btree (slug);

CREATE INDEX idx_product_specs_definition ON public.product_spec USING btree (spec_definition_id);

CREATE INDEX idx_product_specs_numeric ON public.product_spec USING btree (numeric_value);

CREATE INDEX idx_product_specs_product ON public.product_spec USING btree (product_id);

CREATE INDEX idx_products_brand ON public.product USING btree (brand_id);

CREATE INDEX idx_products_category ON public.product USING btree (category_id);

CREATE INDEX idx_products_raw_data ON public.product USING gin (raw_data);

CREATE INDEX idx_products_slug ON public.product USING btree (slug);

CREATE INDEX idx_spec_mappings_pattern ON public.spec_mapping USING btree (extraction_pattern);

CREATE UNIQUE INDEX product_categories_pkey ON public.product_category USING btree (id);

CREATE UNIQUE INDEX product_categories_slug_key ON public.product_category USING btree (slug);

CREATE UNIQUE INDEX product_spec_matrix_v2_pkey ON public.product_spec_matrix USING btree (id);

CREATE UNIQUE INDEX product_spec_matrix_v2_product_id_spec_definition_id_dims_key ON public.product_spec_matrix USING btree (product_id, spec_definition_id, dims);

CREATE UNIQUE INDEX product_specs_pkey ON public.product_spec USING btree (id);

CREATE UNIQUE INDEX product_specs_product_id_spec_definition_id_key ON public.product_spec USING btree (product_id, spec_definition_id);

CREATE UNIQUE INDEX products_pkey ON public.product USING btree (id);

CREATE UNIQUE INDEX products_slug_key ON public.product USING btree (slug);

CREATE UNIQUE INDEX spec_definitions_normalized_key_key ON public.spec_definition USING btree (normalized_key);

CREATE UNIQUE INDEX spec_definitions_pkey ON public.spec_definition USING btree (id);

CREATE UNIQUE INDEX spec_mappings_pkey ON public.spec_mapping USING btree (id);

CREATE UNIQUE INDEX spec_sections_pkey ON public.spec_section USING btree (id);

CREATE UNIQUE INDEX spec_sections_section_name_category_id_key ON public.spec_section USING btree (section_name, category_id);

alter table "public"."brand" add constraint "brands_pkey" PRIMARY KEY using index "brands_pkey";

alter table "public"."product" add constraint "products_pkey" PRIMARY KEY using index "products_pkey";

alter table "public"."product_category" add constraint "product_categories_pkey" PRIMARY KEY using index "product_categories_pkey";

alter table "public"."product_spec" add constraint "product_specs_pkey" PRIMARY KEY using index "product_specs_pkey";

alter table "public"."product_spec_matrix" add constraint "product_spec_matrix_v2_pkey" PRIMARY KEY using index "product_spec_matrix_v2_pkey";

alter table "public"."spec_definition" add constraint "spec_definitions_pkey" PRIMARY KEY using index "spec_definitions_pkey";

alter table "public"."spec_mapping" add constraint "spec_mappings_pkey" PRIMARY KEY using index "spec_mappings_pkey";

alter table "public"."spec_section" add constraint "spec_sections_pkey" PRIMARY KEY using index "spec_sections_pkey";

alter table "public"."brand" add constraint "brands_name_key" UNIQUE using index "brands_name_key";

alter table "public"."brand" add constraint "brands_slug_key" UNIQUE using index "brands_slug_key";

alter table "public"."product" add constraint "products_brand_id_fkey" FOREIGN KEY (brand_id) REFERENCES public.brand(id) not valid;

alter table "public"."product" validate constraint "products_brand_id_fkey";

alter table "public"."product" add constraint "products_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.product_category(id) not valid;

alter table "public"."product" validate constraint "products_category_id_fkey";

alter table "public"."product" add constraint "products_slug_key" UNIQUE using index "products_slug_key";

alter table "public"."product_category" add constraint "product_categories_parent_category_id_fkey" FOREIGN KEY (parent_category_id) REFERENCES public.product_category(id) not valid;

alter table "public"."product_category" validate constraint "product_categories_parent_category_id_fkey";

alter table "public"."product_category" add constraint "product_categories_slug_key" UNIQUE using index "product_categories_slug_key";

alter table "public"."product_spec" add constraint "product_specs_product_id_fkey" FOREIGN KEY (product_id) REFERENCES public.product(id) ON DELETE CASCADE not valid;

alter table "public"."product_spec" validate constraint "product_specs_product_id_fkey";

alter table "public"."product_spec" add constraint "product_specs_product_id_spec_definition_id_key" UNIQUE using index "product_specs_product_id_spec_definition_id_key";

alter table "public"."product_spec" add constraint "product_specs_spec_definition_id_fkey" FOREIGN KEY (spec_definition_id) REFERENCES public.spec_definition(id) not valid;

alter table "public"."product_spec" validate constraint "product_specs_spec_definition_id_fkey";

alter table "public"."product_spec_matrix" add constraint "product_spec_matrix_v2_product_id_fkey" FOREIGN KEY (product_id) REFERENCES public.product(id) ON DELETE CASCADE not valid;

alter table "public"."product_spec_matrix" validate constraint "product_spec_matrix_v2_product_id_fkey";

alter table "public"."product_spec_matrix" add constraint "product_spec_matrix_v2_product_id_spec_definition_id_dims_key" UNIQUE using index "product_spec_matrix_v2_product_id_spec_definition_id_dims_key";

alter table "public"."product_spec_matrix" add constraint "product_spec_matrix_v2_spec_definition_id_fkey" FOREIGN KEY (spec_definition_id) REFERENCES public.spec_definition(id) ON DELETE CASCADE not valid;

alter table "public"."product_spec_matrix" validate constraint "product_spec_matrix_v2_spec_definition_id_fkey";

alter table "public"."spec_definition" add constraint "spec_definitions_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.product_category(id) not valid;

alter table "public"."spec_definition" validate constraint "spec_definitions_category_id_fkey";

alter table "public"."spec_definition" add constraint "spec_definitions_normalized_key_key" UNIQUE using index "spec_definitions_normalized_key_key";

alter table "public"."spec_definition" add constraint "spec_definitions_section_id_fkey" FOREIGN KEY (section_id) REFERENCES public.spec_section(id) not valid;

alter table "public"."spec_definition" validate constraint "spec_definitions_section_id_fkey";

alter table "public"."spec_mapping" add constraint "spec_mappings_spec_definition_id_fkey" FOREIGN KEY (spec_definition_id) REFERENCES public.spec_definition(id) not valid;

alter table "public"."spec_mapping" validate constraint "spec_mappings_spec_definition_id_fkey";

alter table "public"."spec_section" add constraint "spec_sections_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.product_category(id) not valid;

alter table "public"."spec_section" validate constraint "spec_sections_category_id_fkey";

alter table "public"."spec_section" add constraint "spec_sections_parent_section_id_fkey" FOREIGN KEY (parent_section_id) REFERENCES public.spec_section(id) not valid;

alter table "public"."spec_section" validate constraint "spec_sections_parent_section_id_fkey";

alter table "public"."spec_section" add constraint "spec_sections_section_name_category_id_key" UNIQUE using index "spec_sections_section_name_category_id_key";

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.product FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


