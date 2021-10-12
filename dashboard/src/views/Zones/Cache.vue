<template>
  <div class="row row-deck row-cards">
    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Enable Cache</h3>
        </div>
        <div class="card-body">
          <p>Cache responses on the edge</p>
        </div>
        <div class="card-footer d-flex flex-row-reverse">
          <label class="form-check form-switch m-0 float-end">
            <input
              class="form-check-input position-static"
              type="checkbox"
              checked=""
            />
          </label>
        </div>
      </div>
    </div>

    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Cache TTL</h3>
        </div>
        <div class="card-body">
          <p>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit. Aperiam
            deleniti fugit incidunt, iste, itaque minima neque pariatur
            perferendis sed suscipit velit vitae voluptatem.
          </p>
        </div>
        <div class="card-footer d-flex flex-row-reverse">
          <label class="form-check form-switch m-0 float-end">
            <input
              class="form-check-input position-static"
              type="checkbox"
              checked=""
            />
          </label>
        </div>
      </div>
    </div>

    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Query String</h3>
        </div>
        <div class="card-body">
          <p>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit. Aperiam
            deleniti fugit incidunt, iste, itaque minima neque pariatur
            perferendis sed suscipit velit vitae voluptatem.
          </p>
        </div>
        <div class="card-footer d-flex flex-row-reverse">
          <label class="form-check form-switch m-0 float-end">
            <input
              class="form-check-input position-static"
              type="checkbox"
              checked=""
            />
          </label>
        </div>
      </div>
    </div>

    <div class="col-12 col-md-5">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Strip Cookies</h3>
        </div>
        <div class="card-body">
          <p>Remove cookies from proxied responses</p>
        </div>
        <div class="card-footer d-flex flex-row-reverse">
          <label class="form-check form-switch m-0 float-end">
            <input
              class="form-check-input position-static"
              type="checkbox"
              checked=""
            />
          </label>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ZonesCache',
};
</script>
