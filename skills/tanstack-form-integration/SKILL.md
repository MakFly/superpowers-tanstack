---
name: tanstack:tanstack-form-integration
description: TanStack Form integration for form handling - validation, state management, and field management
---

# TanStack Form Integration for TanStack Start

TanStack Form provides flexible, performant form handling with first-class TypeScript support, validation framework integration, and fine-grained reactivity.

## Installation & Setup

### Install Dependencies

```bash
npm install @tanstack/react-form
npm install zod @hookform/resolvers  # For validation
```

### Basic Form Setup

```typescript
// src/components/ContactForm.tsx
import { useForm } from '@tanstack/react-form';
import { zodValidator } from '@tanstack/zod-form-adapter';
import { z } from 'zod';

// Define validation schema
const contactSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  message: z.string().min(10, 'Message must be at least 10 characters'),
});

type ContactFormData = z.infer<typeof contactSchema>;

export function ContactForm() {
  const form = useForm({
    defaultValues: {
      name: '',
      email: '',
      message: '',
    },
    onSubmit: async ({ value }) => {
      // Send to server
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(value),
      });
      return response.json();
    },
    validatorAdapter: zodValidator(),
  });

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        form.handleSubmit();
      }}
    >
      <form.Field
        name="name"
        validators={{
          onChange: contactSchema.shape.name,
        }}
      >
        {(field) => (
          <div>
            <label htmlFor={field.name}>Name</label>
            <input
              id={field.name}
              name={field.name}
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
              onBlur={field.handleBlur}
            />
            {field.state.meta.errors.length > 0 && (
              <span className="error">{field.state.meta.errors[0]}</span>
            )}
          </div>
        )}
      </form.Field>

      {/* Email field */}
      <form.Field
        name="email"
        validators={{
          onChange: contactSchema.shape.email,
        }}
      >
        {(field) => (
          <div>
            <label htmlFor={field.name}>Email</label>
            <input
              id={field.name}
              name={field.name}
              type="email"
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
              onBlur={field.handleBlur}
            />
            {field.state.meta.errors.length > 0 && (
              <span className="error">{field.state.meta.errors[0]}</span>
            )}
          </div>
        )}
      </form.Field>

      {/* Message field */}
      <form.Field
        name="message"
        validators={{
          onChange: contactSchema.shape.message,
        }}
      >
        {(field) => (
          <div>
            <label htmlFor={field.name}>Message</label>
            <textarea
              id={field.name}
              name={field.name}
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
              onBlur={field.handleBlur}
            />
            {field.state.meta.errors.length > 0 && (
              <span className="error">{field.state.meta.errors[0]}</span>
            )}
          </div>
        )}
      </form.Field>

      <form.Subscribe
        selector={(state) => [state.isSubmitting]}
      >
        {([isSubmitting]) => (
          <button type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Sending...' : 'Send'}
          </button>
        )}
      </form.Subscribe>
    </form>
  );
}
```

## Field Management

### Using FieldInfo

```typescript
// Better field handling with extracted field info
function ContactForm() {
  const form = useForm({
    defaultValues: { name: '', email: '' },
    onSubmit: ({ value }) => submitForm(value),
  });

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit(); }}>
      <form.Field name="name">
        {(field) => <FieldInput field={field} label="Name" />}
      </form.Field>

      <form.Field name="email">
        {(field) => <FieldInput field={field} label="Email" type="email" />}
      </form.Field>

      <SubmitButton form={form} />
    </form>
  );
}

// Reusable field component
function FieldInput({
  field,
  label,
  type = 'text',
  ...rest
}: {
  field: any;
  label: string;
  type?: string;
}) {
  const [error] = field.state.meta.errors;

  return (
    <div className="field">
      <label htmlFor={field.name}>{label}</label>
      <input
        id={field.name}
        name={field.name}
        type={type}
        value={field.state.value}
        onChange={(e) => field.handleChange(e.target.value)}
        onBlur={field.handleBlur}
        className={error ? 'error' : ''}
        {...rest}
      />
      {error && <span className="error-message">{error}</span>}
    </div>
  );
}

// Submit button with loading state
function SubmitButton({ form }: { form: any }) {
  const [isSubmitting] = form.state.isSubmitting;

  return (
    <button type="submit" disabled={isSubmitting}>
      {isSubmitting ? 'Submitting...' : 'Submit'}
    </button>
  );
}
```

## Validation Patterns

### Schema Validation

```typescript
// Using Zod for type-safe validation
import { z } from 'zod';

const userSchema = z.object({
  username: z.string()
    .min(3, 'Username must be at least 3 characters')
    .max(20, 'Username must be less than 20 characters')
    .regex(/^[a-zA-Z0-9_-]+$/, 'Username can only contain letters, numbers, underscores, and hyphens'),

  email: z.string()
    .email('Invalid email address'),

  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain an uppercase letter')
    .regex(/[0-9]/, 'Password must contain a number'),

  confirmPassword: z.string(),

  age: z.number()
    .min(18, 'Must be at least 18 years old')
    .max(150, 'Invalid age'),

  terms: z.boolean()
    .refine((val) => val === true, 'You must accept the terms'),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});
```

### Async Validation

```typescript
// Server-side validation (e.g., check username availability)
const signupSchema = z.object({
  username: z.string()
    .min(3)
    .refine(
      async (username) => {
        const response = await fetch(`/api/check-username?u=${username}`);
        const { available } = await response.json();
        return available;
      },
      'Username already taken'
    ),
});
```

### Field-level Validation

```typescript
// Validate on change (real-time feedback)
form.Field
  name="email"
  validators={{
    onChange: async ({ value }) => {
      if (!value.includes('@')) {
        return 'Invalid email format';
      }

      // Check email not already registered
      const { exists } = await fetch(`/api/email-exists?e=${value}`)
        .then(r => r.json());

      if (exists) {
        return 'Email already registered';
      }
    },
  }}
```

### Form-level Validation

```typescript
// Validate entire form before submission
form.Form
  validators={{
    onSubmit: async ({ value }) => {
      const result = userSchema.safeParse(value);

      if (!result.success) {
        return {
          form: result.error.message,
        };
      }

      // Additional custom validation
      if (value.password === value.username) {
        return {
          form: 'Password cannot be the same as username',
        };
      }
    },
  }}
```

## Complex Form Patterns

### Multi-step Form

```typescript
// Two-step registration form
function RegistrationWizard() {
  const [step, setStep] = useState(1);

  const form = useForm({
    defaultValues: {
      // Step 1
      email: '',
      password: '',
      // Step 2
      firstName: '',
      lastName: '',
      companyName: '',
    },
    onSubmit: async ({ value }) => {
      // Submit all data at once
      return createAccount(value);
    },
  });

  return (
    <form>
      {step === 1 ? (
        <Step1Fields form={form} />
      ) : (
        <Step2Fields form={form} />
      )}

      <div className="buttons">
        {step > 1 && (
          <button type="button" onClick={() => setStep(step - 1)}>
            Back
          </button>
        )}

        {step < 2 ? (
          <button
            type="button"
            onClick={() => setStep(step + 1)}
          >
            Next
          </button>
        ) : (
          <button type="submit">Complete Registration</button>
        )}
      </div>
    </form>
  );
}

function Step1Fields({ form }: { form: any }) {
  return (
    <>
      <h2>Account Details</h2>
      <form.Field name="email">
        {(field) => <FieldInput field={field} label="Email" type="email" />}
      </form.Field>
      <form.Field name="password">
        {(field) => <FieldInput field={field} label="Password" type="password" />}
      </form.Field>
    </>
  );
}

function Step2Fields({ form }: { form: any }) {
  return (
    <>
      <h2>Personal Information</h2>
      <form.Field name="firstName">
        {(field) => <FieldInput field={field} label="First Name" />}
      </form.Field>
      <form.Field name="lastName">
        {(field) => <FieldInput field={field} label="Last Name" />}
      </form.Field>
      <form.Field name="companyName">
        {(field) => <FieldInput field={field} label="Company" />}
      </form.Field>
    </>
  );
}
```

### Dynamic Fields

```typescript
// Form with variable number of fields
function JobApplicationForm() {
  const form = useForm({
    defaultValues: {
      education: [{ school: '', degree: '' }],
    },
    onSubmit: ({ value }) => submitApplication(value),
  });

  return (
    <form>
      <h2>Education</h2>

      <form.Field name="education">
        {(field) => (
          <div>
            {field.state.value.map((edu, index) => (
              <div key={index}>
                <form.Field name={`education.${index}.school`}>
                  {(schoolField) => (
                    <input
                      name={schoolField.name}
                      value={schoolField.state.value}
                      onChange={(e) => schoolField.handleChange(e.target.value)}
                      placeholder="School/University"
                    />
                  )}
                </form.Field>

                <form.Field name={`education.${index}.degree`}>
                  {(degreeField) => (
                    <input
                      name={degreeField.name}
                      value={degreeField.state.value}
                      onChange={(e) => degreeField.handleChange(e.target.value)}
                      placeholder="Degree"
                    />
                  )}
                </form.Field>
              </div>
            ))}

            <button
              type="button"
              onClick={() => {
                field.pushValue({ school: '', degree: '' });
              }}
            >
              Add Education
            </button>
          </div>
        )}
      </form.Field>

      <button type="submit">Submit</button>
    </form>
  );
}
```

### Dependent Fields

```typescript
// Fields that depend on other field values
function AddressForm() {
  const form = useForm({
    defaultValues: {
      country: '',
      state: '',
      city: '',
    },
    onSubmit: ({ value }) => submitAddress(value),
  });

  return (
    <form>
      <form.Field name="country">
        {(field) => (
          <select
            value={field.state.value}
            onChange={(e) => field.handleChange(e.target.value)}
          >
            <option value="">Select Country</option>
            <option value="US">United States</option>
            <option value="CA">Canada</option>
          </select>
        )}
      </form.Field>

      {/* State field only shows for US */}
      <form.Subscribe
        selector={(state) => [state.values.country]}
      >
        {([country]) =>
          country === 'US' && (
            <form.Field name="state">
              {(field) => (
                <select
                  value={field.state.value}
                  onChange={(e) => field.handleChange(e.target.value)}
                >
                  <option value="">Select State</option>
                  {US_STATES.map((state) => (
                    <option key={state} value={state}>{state}</option>
                  ))}
                </select>
              )}
            </form.Field>
          )
        }
      </form.Subscribe>

      <form.Field name="city">
        {(field) => (
          <input
            value={field.state.value}
            onChange={(e) => field.handleChange(e.target.value)}
            placeholder="City"
          />
        )}
      </form.Field>

      <button type="submit">Save Address</button>
    </form>
  );
}
```

## Form State Management

### Monitoring Form State

```typescript
// Subscribe to form state changes
function FormWithStateDisplay() {
  const form = useForm({
    defaultValues: { email: '', password: '' },
    onSubmit: ({ value }) => submitForm(value),
  });

  return (
    <div>
      <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit(); }}>
        {/* Form fields */}
      </form>

      {/* Display form state */}
      <form.Subscribe selector={(state) => [state]}>
        {([state]) => (
          <div className="debug">
            <h3>Form State</h3>
            <pre>
              {JSON.stringify(
                {
                  isDirty: state.isDirty,
                  isTouched: state.isTouched,
                  isSubmitting: state.isSubmitting,
                  isValidating: state.isValidating,
                  errors: state.errors,
                  values: state.values,
                },
                null,
                2
              )}
            </pre>
          </div>
        )}
      </form.Subscribe>
    </div>
  );
}
```

### Save State to LocalStorage

```typescript
// Persist form data to prevent loss on page reload
function PersistentForm() {
  const form = useForm({
    defaultValues: getInitialValues(),
    onSubmit: ({ value }) => submitForm(value),
  });

  // Save to localStorage on changes
  form.Subscribe(
    selector={(state) => state.values},
    () => {
      localStorage.setItem('formDraft', JSON.stringify(form.state.values));
    }
  );

  const handleClear = () => {
    localStorage.removeItem('formDraft');
    form.reset();
  };

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit(); }}>
      {/* Form fields */}
      <button type="submit">Submit</button>
      <button type="button" onClick={handleClear}>Clear Draft</button>
    </form>
  );
}

function getInitialValues() {
  const draft = localStorage.getItem('formDraft');
  return draft ? JSON.parse(draft) : { email: '', password: '' };
}
```

## Submission Handling

### Form Submission with Error Handling

```typescript
const form = useForm({
  defaultValues: { email: '', password: '' },
  onSubmit: async ({ value }) => {
    try {
      const response = await fetch('/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(value),
      });

      if (!response.ok) {
        if (response.status === 401) {
          throw new Error('Invalid email or password');
        }
        throw new Error('Login failed');
      }

      const data = await response.json();
      // Success - redirect or update state
      window.location.href = '/dashboard';
    } catch (error) {
      // Form-level error
      form.setFieldValue('form', error.message);
    }
  },
});
```

## Testing Forms

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('form submission with validation', async () => {
  const user = userEvent.setup();
  render(<ContactForm />);

  // Submit without filling fields
  fireEvent.click(screen.getByRole('button', { name: /submit/i }));

  // Errors should show
  await waitFor(() => {
    expect(screen.getByText('Name must be at least 2 characters')).toBeInTheDocument();
  });

  // Fill and submit
  await user.type(screen.getByLabelText('Name'), 'John Doe');
  await user.type(screen.getByLabelText('Email'), 'john@example.com');
  await user.type(screen.getByLabelText('Message'), 'This is a test message');

  fireEvent.click(screen.getByRole('button', { name: /send/i }));

  // Wait for success
  await waitFor(() => {
    expect(screen.getByText('Message sent successfully')).toBeInTheDocument();
  });
});
```

## Integration with TanStack Query

```typescript
// Use mutations with forms
function CreatePostForm() {
  const form = useForm({
    defaultValues: { title: '', content: '' },
    onSubmit: ({ value }) => createPostMutation(value),
  });

  const { mutate: createPostMutation, isPending } = useMutation({
    mutationFn: async (data) => {
      const response = await fetch('/api/posts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      return response.json();
    },
    onSuccess: () => {
      form.reset();
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit(); }}>
      {/* Form fields */}
      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create'}
      </button>
    </form>
  );
}
```

## Resources

- [TanStack Form Documentation](https://tanstack.com/form/latest)
- [Zod Validation](https://zod.dev)
- [Form Patterns Guide](https://tanstack.com/form/latest/docs/guide/introduction)
