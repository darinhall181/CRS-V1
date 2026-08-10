CREATE TYPE "public"."workspace_type" AS ENUM('production', 'rental', 'hobbyist');--> statement-breakpoint
CREATE TABLE "user_profile" (
	"user_id" uuid PRIMARY KEY NOT NULL,
	"home_market" text,
	"referral_source" text,
	"day_rate_band" text,
	"union_status" text,
	"has_owner_kit" boolean DEFAULT false NOT NULL,
	"owner_kit_categories" text[],
	"insurance_status" text
);
--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "workspace_type" "workspace_type";--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "profession" text;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "onboarding_completed_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "user_profile" ADD CONSTRAINT "user_profile_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;