# frozen_string_literal: true

require "tw_parser/utils/math_operators"

RSpec.describe "math_operators" do
  describe ".add_whitespace", :aggregate_failures do
    def run(input)
      TwParser::Utils::MathOperators.add_whitespace(input)
    end

    it "basic arithmetic operations" do
      expect(run("calc(1+2)")).to eq("calc(1 + 2)")
      expect(run("calc(100%-2rem)")).to eq("calc(100% - 2rem)")
      expect(run("calc(2*3)")).to eq("calc(2 * 3)")
      expect(run("calc(10px/2)")).to eq("calc(10px / 2)")
    end

    it "complex expressions" do
      expect(run("calc((100%-1rem)/2)")).to eq("calc((100% - 1rem) / 2)")
      expect(run("calc(+2--3)")).to eq("calc(+2 - -3)")
      expect(run("calc(.5*2)")).to eq("calc(.5 * 2)")
      expect(run("calc(1e3-5)")).to eq("calc(1e3 - 5)")
      expect(run("calc(100%/*g*/-1rem)")).to eq("calc(100% / *g * /-1rem)")
      expect(run("calc(100%/**/-/**/1rem)")).to eq("calc(100% / **/-/**/1rem)")
      expect(run("calc( (100%-1rem)/2 )")).to eq("calc( (100% - 1rem) / 2 )")
      expect(run("calc(100%-1rem-1rem)")).to eq("calc(100% - 1rem - 1rem)")
      expect(run("calc((100%-2rem)/(1+1))")).to eq("calc((100% - 2rem) / (1 + 1))")
      expect(run("calc(1+-2)")).to eq("calc(1 + -2)")
      expect(run("calc(-1+2)")).to eq("calc(-1 + 2)")
      expect(run("calc(1-+2)")).to eq("calc(1 - +2)")
      expect(run("calc(1+(2*(3-4)))")).to eq("calc(1 + (2 * (3 - 4)))")
      expect(run("calc((1+2)*(3+4))")).to eq("calc((1 + 2) * (3 + 4))")
      expect(run("calc(1/2*3)")).to eq("calc(1 / 2 * 3)")
      expect(run("calc(1*2/3)")).to eq("calc(1 * 2 / 3)")
      expect(run("calc(1-2+3)")).to eq("calc(1 - 2 + 3)")
      expect(run("calc( (1+2) -(-3) )")).to eq("calc( (1 + 2) - (-3) )")
      expect(run("calc( (1+-2)*(-3+4) )")).to eq("calc( (1 + -2) * (-3 + 4) )")
    end

    it "handles nested calculations" do
      expect(run("calc(100%-calc(2rem+10px))")).to eq("calc(100% - calc(2rem + 10px))")
      expect(run("min(50vw,calc(100%-2rem))")).to eq("min(50vw, calc(100% - 2rem))")
      expect(run("calc(1rem+var(--scale,calc(1vw+2px)))")).to eq("calc(1rem + var(--scale,calc(1vw + 2px)))")
    end

    it "min / max / clamp" do
      expect(run("min(50vw,500px)")).to eq("min(50vw, 500px)")
      expect(run("max(10vh,120px)")).to eq("max(10vh, 120px)")
      expect(run("clamp(1rem,2vw,2.5rem)")).to eq("clamp(1rem, 2vw, 2.5rem)")
      expect(run("clamp(12px,calc(1rem+1vw),48px)")).to eq("clamp(12px, calc(1rem + 1vw), 48px)")
      expect(run("min(10px,2em,5vw)")).to eq("min(10px, 2em, 5vw)")
      expect(run("max(10px,2em)")).to eq("max(10px, 2em)")
      expect(run("clamp(1rem,1rem+2vw,2.5rem)")).to eq("clamp(1rem, 1rem + 2vw, 2.5rem)")
      expect(run("clamp(1rem,calc(1rem+2vw),2.5rem)")).to eq("clamp(1rem, calc(1rem + 2vw), 2.5rem)")
      expect(run("min(calc(50%-1rem),48ch)")).to eq("min(calc(50% - 1rem), 48ch)")
      expect(run("max(1px,calc(1rem-2px))")).to eq("max(1px, calc(1rem - 2px))")
    end

    it "mixed var / env / attr" do
      expect(run("calc(var(--gutter,16px)*2)")).to eq("calc(var(--gutter,16px) * 2)")
      expect(run("calc(var(--g,16px)*2)")).to eq("calc(var(--g,16px) * 2)")
      expect(run("calc(100%-var(--sidebar,25%))")).to eq("calc(100% - var(--sidebar,25%))")
      expect(run("calc(env(safe-area-inset-left,0px)+8px)")).to eq("calc(env(safe-area-inset-left,0px) + 8px)")
      expect(run("calc(attr(data-size length,10px)*2)")).to eq("calc(attr(data-size length,10px) * 2)")
      expect(run("calc(1rem/var(--n,2))")).to eq("calc(1rem / var(--n,2))")
    end

    # 角度・時間・単位
    it "handles angles, times, frequencies, resolutions, lengths" do
      expect(run("calc(30deg+0.25turn)")).to eq("calc(30deg + 0.25turn)")
      expect(run("calc(200ms+0.2s)")).to eq("calc(200ms + 0.2s)")
      expect(run("calc(100grad-1rad)")).to eq("calc(100grad - 1rad)")
      expect(run("calc(50%+10px)")).to eq("calc(50% + 10px)")
      expect(run("calc(2*1rem)")).to eq("calc(2 * 1rem)")
      expect(run("calc(1rem/2)")).to eq("calc(1rem / 2)")
      expect(run("calc((1rem+2px))")).to eq("calc((1rem + 2px))")
      expect(run("calc(.25rem+.75rem)")).to eq("calc(.25rem + .75rem)")
      expect(run("calc(2.0rem-1.0rem)")).to eq("calc(2.0rem - 1.0rem)")
      expect(run("calc(10px,2px)")).to eq("calc(10px, 2px)")
      expect(run("calc(50cqw-1rem)")).to eq("calc(50cqw - 1rem)")
      expect(run("calc(1cap+2px)")).to eq("calc(1cap + 2px)")
      expect(run("calc(1lh*2)")).to eq("calc(1lh * 2)")
    end
  end
end
