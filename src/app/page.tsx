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

        <div className="mt-6">
          <a
            href="https://drive.google.com/file/d/14XIJy6MkfVbcqInx386Fg4V6KqkuckSF/view?usp=drive_link"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center rounded-lg bg-blue-600 px-6 py-3 font-semibold text-white transition hover:bg-blue-500"
          >
            📱 Download Android App
          </a>
          <p className="mt-2 text-sm text-zinc-400">
            Get Video Vault for Android
          </p>
        </div>
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
