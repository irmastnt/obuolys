import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { Button } from "@/components/ui/button";

describe("smoke", () => {
  it("renders shadcn Button with LT label", () => {
    render(<Button>Pradėti</Button>);
    expect(screen.getByRole("button", { name: "Pradėti" })).toBeInTheDocument();
  });
});
