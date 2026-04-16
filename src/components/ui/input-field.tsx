'use client';

import { forwardRef } from 'react';
import { Icon } from './icon';

interface InputFieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  helperText?: string;
  error?: string;
  icon?: string;
  fullWidth?: boolean;
}

export const InputField = forwardRef<HTMLInputElement, InputFieldProps>(
  ({ label, helperText, error, icon, fullWidth = true, className = '', id, ...props }, ref) => {
    const inputId = id || label?.toLowerCase().replace(/\s+/g, '-');

    return (
      <div className={`${fullWidth ? 'w-full' : ''}`}>
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-[var(--color-text)] mb-1.5 tracking-wide uppercase"
            style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)' }}
          >
            {label}
          </label>
        )}
        <div className="relative">
          {icon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]">
              <Icon name={icon} size={20} />
            </div>
          )}
          <input
            ref={ref}
            id={inputId}
            className={`
              w-full border rounded-[var(--radius-md)] px-4 py-2.5 text-base
              bg-[var(--color-surface)] text-[var(--color-text)]
              placeholder:text-[var(--color-text-muted)]
              transition-all duration-fast
              focus:outline-none focus:border-[var(--color-primary)] focus:ring-1 focus:ring-[var(--color-primary-light)]
              ${error ? 'border-[var(--color-error)]' : 'border-[var(--color-border)]'}
              ${icon ? 'pl-10' : ''}
              ${className}
            `.trim()}
            {...props}
          />
        </div>
        {error && (
          <p className="mt-1 text-sm text-[var(--color-error)] flex items-center gap-1">
            <Icon name="error" size={16} />
            {error}
          </p>
        )}
        {helperText && !error && (
          <p className="mt-1 text-sm text-[var(--color-text-muted)]">{helperText}</p>
        )}
      </div>
    );
  }
);

InputField.displayName = 'InputField';
