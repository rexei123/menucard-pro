'use client';

import { Icon } from './icon';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  padding?: 'sm' | 'md' | 'lg';
  hover?: boolean;
  onClick?: () => void;
}

const paddingClasses: Record<string, string> = {
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8',
};

export function Card({ children, className = '', padding = 'md', hover = false, onClick }: CardProps) {
  return (
    <div
      className={`
        bg-[var(--color-surface)] rounded-[var(--radius-lg)] shadow-card
        border border-[var(--color-border-subtle)]
        ${paddingClasses[padding]}
        ${hover ? 'hover:shadow-md hover:border-[var(--color-border)] transition-all duration-normal cursor-pointer' : ''}
        ${className}
      `.trim()}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {children}
    </div>
  );
}

/* KPI-Card für Dashboard */
interface KpiCardProps {
  icon: string;
  iconColor?: string;
  label: string;
  value: string | number;
  trend?: { value: string; positive: boolean };
  className?: string;
}

export function KpiCard({ icon, iconColor = 'var(--color-primary)', label, value, trend, className = '' }: KpiCardProps) {
  return (
    <Card className={className}>
      <div className="flex items-start justify-between mb-3">
        <div
          className="w-10 h-10 rounded-[var(--radius-md)] flex items-center justify-center"
          style={{ backgroundColor: `${iconColor}15` }}
        >
          <Icon name={icon} size={22} className="" />
        </div>
        {trend && (
          <span
            className={`text-xs font-medium px-2 py-0.5 rounded-full flex items-center gap-0.5 ${
              trend.positive
                ? 'text-[var(--color-success)] bg-[var(--color-success-light)]'
                : 'text-[var(--color-error)] bg-[var(--color-error-light)]'
            }`}
          >
            <Icon name={trend.positive ? 'trending_up' : 'trending_down'} size={14} />
            {trend.value}
          </span>
        )}
      </div>
      <p className="text-sm text-[var(--color-text-muted)] mb-1">{label}</p>
      <p className="text-2xl font-bold text-[var(--color-text)]" style={{ fontFamily: 'var(--font-body)' }}>
        {value}
      </p>
    </Card>
  );
}
