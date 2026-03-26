import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Camera, BookOpen, Users, Search, Zap, Target } from "lucide-react"

export default function HomePage() {
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="border-b border-border">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-2">
              <Camera className="h-8 w-8 text-secondary" />
              <span className="text-2xl font-bold text-foreground">Altoscope</span>
            </div>
            <div className="hidden md:flex items-center space-x-8">
              <Link href="/gear" className="text-muted-foreground hover:text-foreground transition-colors">
                Gear Database
              </Link>
              <a href="#features" className="text-muted-foreground hover:text-foreground transition-colors">
                Features
              </a>
              <a href="#pricing" className="text-muted-foreground hover:text-foreground transition-colors">
                Pricing
              </a>
              <Button variant="outline" size="sm">
                Sign In
              </Button>
              <Button size="sm" asChild>
                <Link href="/gear">Explore Gear</Link>
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center">
            <Badge variant="secondary" className="mb-6 bg-secondary/10 text-secondary border-secondary/20">
              Smart Kit Builder for Commercial Productions
            </Badge>
            <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold text-balance mb-6">
              Build validated production kits with <span className="text-secondary">confidence.</span>
            </h1>
            <p className="text-xl text-muted-foreground text-balance max-w-3xl mx-auto mb-8">
              Altoscope turns fragmented public camera specs into compatibility-checked, professional RFQs.
              Stop wrestling with 10 spreadsheets from 10 freelancers — build your kit, run the checks, send the quote.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" asChild>
                <Link href="/gear">Browse Gear Database</Link>
              </Button>
              <Button variant="outline" size="lg">
                See How It Works
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 px-4 sm:px-6 lg:px-8 border-y border-border">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            <div className="text-center">
              <div className="text-3xl font-bold text-secondary mb-2">2,500+</div>
              <div className="text-muted-foreground">Mapped Specs</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-secondary mb-2">183</div>
              <div className="text-muted-foreground">Products Indexed</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-secondary mb-2">4</div>
              <div className="text-muted-foreground">Compatibility Checks</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-secondary mb-2">Canon</div>
              <div className="text-muted-foreground">Brand (more coming)</div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="database" className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">From fragmented specs to a validated kit</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Every tool a producer needs to go from "what do I rent?" to a clean, verified RFQ — without the guesswork.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <Card className="bg-card border-border">
              <CardContent className="p-6">
                <Search className="h-12 w-12 text-secondary mb-4" />
                <h3 className="text-xl font-bold mb-2">Gear Database</h3>
                <p className="text-muted-foreground">
                  Structured, normalized specs for cameras, lenses, and accessories — scraped and verified from
                  manufacturer pages.
                </p>
              </CardContent>
            </Card>

            <Card className="bg-card border-border">
              <CardContent className="p-6">
                <Zap className="h-12 w-12 text-secondary mb-4" />
                <h3 className="text-xl font-bold mb-2">Mount Check</h3>
                <p className="text-muted-foreground">
                  Instantly validate that every body and lens pairing in your kit is physically compatible, including
                  adapter requirements.
                </p>
              </CardContent>
            </Card>

            <Card className="bg-card border-border">
              <CardContent className="p-6">
                <Target className="h-12 w-12 text-secondary mb-4" />
                <h3 className="text-xl font-bold mb-2">Media & Power Check</h3>
                <p className="text-muted-foreground">
                  Verify card reader compatibility, transfer speeds, and battery coverage across your entire kit before
                  shoot day.
                </p>
              </CardContent>
            </Card>

            <Card className="bg-card border-border">
              <CardContent className="p-6">
                <BookOpen className="h-12 w-12 text-secondary mb-4" />
                <h3 className="text-xl font-bold mb-2">Smart List Builder</h3>
                <p className="text-muted-foreground">
                  Build from scratch, use scenario presets, or let the AI advisor suggest gear based on your shoot
                  requirements.
                </p>
              </CardContent>
            </Card>

            <Card className="bg-card border-border">
              <CardContent className="p-6">
                <Users className="h-12 w-12 text-secondary mb-4" />
                <h3 className="text-xl font-bold mb-2">Standardized RFQ Output</h3>
                <p className="text-muted-foreground">
                  Export a clean PDF or shareable link with SKUs and verified specs — ready to send to any rental
                  house.
                </p>
              </CardContent>
            </Card>

            <Card className="bg-card border-border">
              <CardContent className="p-6">
                <Camera className="h-12 w-12 text-secondary mb-4" />
                <h3 className="text-xl font-bold mb-2">Physical Check</h3>
                <p className="text-muted-foreground">
                  Validate accessory dimensions, sum gimbal / drone payload, and get total travel weight — all from
                  spec data.
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-primary/5">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">Stop chasing down gear lists. Start shipping shoots.</h2>
          <p className="text-xl text-muted-foreground mb-8">
            Built for commercial producers who need a verified kit fast — not another spreadsheet.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" asChild>
              <Link href="/gear">Browse Gear Database</Link>
            </Button>
            <Button variant="outline" size="lg">
              View Pricing
            </Button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <Camera className="h-6 w-6 text-secondary" />
                <span className="text-lg font-bold">Altoscope</span>
              </div>
              <p className="text-muted-foreground">
                Empowering visual creators through comprehensive camera equipment knowledge and education.
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Platform</h4>
              <ul className="space-y-2 text-muted-foreground">
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Database
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Guides
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Comparisons
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Reviews
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Community</h4>
              <ul className="space-y-2 text-muted-foreground">
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Forums
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Contributors
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Events
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Newsletter
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Company</h4>
              <ul className="space-y-2 text-muted-foreground">
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    About
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Careers
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Contact
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-foreground transition-colors">
                    Privacy
                  </a>
                </li>
              </ul>
            </div>
          </div>
          <div className="border-t border-border mt-8 pt-8 text-center text-muted-foreground">
            <p>&copy; 2024 Altoscope. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
