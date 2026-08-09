CREATE TABLE "package_department_budget" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"package_id" uuid NOT NULL,
	"department" text NOT NULL,
	"approved_amount" numeric(12, 2) NOT NULL,
	"set_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "package_department_budget_package_id_department_unique" UNIQUE("package_id","department")
);
--> statement-breakpoint
ALTER TABLE "package_department_budget" ADD CONSTRAINT "package_department_budget_package_id_packages_id_fk" FOREIGN KEY ("package_id") REFERENCES "public"."packages"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "package_department_budget" ADD CONSTRAINT "package_department_budget_set_by_users_id_fk" FOREIGN KEY ("set_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;