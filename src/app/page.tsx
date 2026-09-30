import { CategoryColumn } from "@/components/CategoryColumn";
import { CATEGORIES } from "@/lib/constants";

export default function HomePage() {
  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <div className="mb-10 text-center">
        <h1 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
          Discover Videos
        </h1>
        <p className="mt-2 text-zinc-400">
          Browse by category, download to watch offline anytime
        </p>
      </div>

      <div className="grid grid-cols-1 gap-8 md:grid-cols-2 xl:grid-cols-4">
        {CATEGORIES.map((category) => (
          <CategoryColumn
            key={category.key}
            categoryKey={category.key}
            label={category.label}
            color={category.color}
            icon={category.icon}
          />
        ))}
      </div>
    </div>
  );
}
